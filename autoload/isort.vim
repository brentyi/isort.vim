function! s:IsortLineCallback(stdout)
    call add(s:formatted_lines, a:stdout)
endfunction

function! s:IsortDoneCallback(startline, endline)
    " Add some extra lines if our output is longer than our input
    let l:endline = a:endline
    while len(s:formatted_lines) - 1 > l:endline - a:startline
        call append(l:endline, "")
        let l:endline += 1
    endwhile

    " Set lines from isort
    call setline(a:startline, s:formatted_lines)

    " Delete any extra lines if we've shortened our buffer
    if a:startline + len(s:formatted_lines) <= l:endline
        let l:cursor_pos = getpos('.')
        execute (a:startline + len(s:formatted_lines)) . ',' . l:endline . 'd _'
        call setpos('.', l:cursor_pos)
    endif
endfunction

function! isort#IsortLines(startline, endline)
    if !executable('isort')
        echoerr 'isort is not installed!'
        return
    endif

    let s:formatted_lines = []
    let l:cmd = 'isort -'
    let l:lines = join(getline(a:startline, a:endline), "\n")
    if has('*jobstart')
        " Neovim (async)
        if exists('s:job')
            call jobstop(s:job)
        endif

        let s:job = jobstart(l:cmd, {
            \ 'on_stdout': {_c, m, _e -> s:IsortLineCallback(m)},
            \ 'on_exit': {_c, _m, _e -> s:IsortDoneCallback(a:startline, a:endline)},
            \ })

        if exists('*chansend')
            " Neovim >0.3.0
            call chansend(s:job, l:lines)
            call chanclose(s:job, 'stdin')
        else
            " Legacy API
            call jobsend(s:job, l:lines)
            call jobclose(s:job, 'stdin')
        endif

    elseif exists('*job_start')
        " Vim 8 (async)
        if exists('s:job') && job_status(s:job) != 'stop'
            call job_stop(s:job)
        endif

        let s:job = job_start(l:cmd, {
            \ 'callback': {_, m -> s:IsortLineCallback(m)},
            \ 'exit_cb': {_, _m -> s:IsortDoneCallback(a:startline, a:endline)},
            \ 'in_mode': 'nl',
            \ })

        let channel = job_getchannel(s:job)
        if ch_status(channel) ==# 'open'
            call ch_sendraw(channel, l:lines)
            call ch_close_in(channel)
        endif
    else
        " Legacy (synchronous)
        let l:cursor_pos = getpos('.')
        execute a:startline . ',' . a:endline . '! isort -'
        call setpos('.', l:cursor_pos)
    endif
endfunction
