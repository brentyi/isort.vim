function! s:IsortLineCallback(formatted_line)
    if s:startline + s:line_counter <= s:endline
        " Modify an existing line
        call setline(s:startline + s:line_counter, a:formatted_line)
    else
        " Add a new line
        call append(s:endline, a:formatted_line)
        let s:endline += 1
    endif

    " Increment line counter
    let s:line_counter += 1
endfunction

function! s:IsortDoneCallback()
    " Delete extra lines if formatting has shortened our buffer
    if s:startline + s:line_counter <= s:endline
        let l:cursor_pos = getpos('.')
        execute (s:startline + s:line_counter) . ',' . s:endline . 'd _'
        call setpos('.', l:cursor_pos)
    endif

    " Done!
    if exists('s:callback')
        call s:callback()
    endif
endfunction

function! isort#Isort(startline, endline, ...)
    " Make sure isort is installed
    if !executable('isort')
        echoerr 'isort is not installed!'
        return
    endif

    " Initialize (global-ish) state
    let s:startline = a:startline
    let s:endline = a:endline
    let s:line_counter = 0

    " Accept callback
    if a:0 == 1
        let s:callback = a:1
    elseif exists('s:callback')
        unlet s:callback
    endif

    " Start job
    let l:cmd = 'isort -'
    let l:lines = join(getline(a:startline, a:endline), "\n")
    if has('*jobstart')
        " Neovim (async)
        if exists('s:job')
            call jobstop(s:job)
        endif

        let s:job = jobstart(l:cmd, {
            \ 'on_stdout': {_c, m, _e -> s:IsortLineCallback(m)},
            \ 'on_exit': {_c, _m, _e -> s:IsortDoneCallback()},
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

    elseif v:version >= 800
        " Vim 8 (async)
        " Note that 7.4 can be compiled with the +job flag, but the API has
        " evolved a lot...
        if exists('s:job') && job_status(s:job) != 'stop'
            call job_stop(s:job)
        endif

        let s:job = job_start(l:cmd, {
            \ 'callback': {_, m -> s:IsortLineCallback(m)},
            \ 'exit_cb': {_, _m -> s:IsortDoneCallback()},
            \ 'in_mode': 'nl',
            \ })

        let l:channel = job_getchannel(s:job)
        if ch_status(l:channel) ==# 'open'
            call ch_sendraw(l:channel, l:lines)
            call ch_close_in(l:channel)
        endif
    else
        " Legacy (synchronous)
        let l:cursor_pos = getpos('.')
        execute a:startline . ',' . a:endline . '! isort -'
        call setpos('.', l:cursor_pos)

        " Done!
        if exists('s:callback')
            call s:callback()
        endif
    endif
endfunction
