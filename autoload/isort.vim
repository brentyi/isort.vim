function! s:IsortLineCallback(formatted_lines)
    if has('nvim')
        " We get an extra blank line in Neovim
        " Not really sure why...
        let l:formatted_lines = a:formatted_lines[:-2]
    else
        let l:formatted_lines = a:formatted_lines
    endif
    if s:start_line + s:line_counter <= s:end_line
        " Modify existing lines
        for l:offset in range(len(l:formatted_lines))
            let l:line_number = s:start_line + s:line_counter + l:offset
            if getline(l:line_number) !=# l:formatted_lines[l:offset]
                call setline(l:line_number, l:formatted_lines[l:offset])
            endif
        endfor
    else
        " Add a new line
        echom string(l:formatted_lines)
        call append(s:end_line, l:formatted_lines)
        let s:end_line += len(l:formatted_lines)
    endif

    " Increment line counter
    let s:line_counter += len(a:formatted_lines)
endfunction

function! s:IsortDoneCallback()
    unlet s:job

    " Delete extra lines if formatting has shortened our buffer
    if s:start_line + s:line_counter <= s:end_line
        let l:cursor_pos = getpos('.')
        execute (s:start_line + s:line_counter) . ',' . s:end_line . 'd _'
        call setpos('.', l:cursor_pos)
    endif

    " Done!
    if exists('s:callback')
        call s:callback()
    endif
endfunction

function! isort#Isort(start_line, end_line, ...)
    " Make sure isort is installed
    if !executable('isort')
        echoerr 'isort is not installed!'
        return
    endif

    " Initialize (global-ish) state
    let s:start_line = a:start_line
    let s:end_line = a:end_line
    let s:line_counter = 0

    " Accept callback
    if a:0 == 1
        let s:callback = a:1
    elseif exists('s:callback')
        unlet s:callback
    endif

    " Start job
    let l:cmd = 'isort -'
    let l:lines = join(getline(a:start_line, a:end_line), "\n")
    if exists('*jobstart')
        " Neovim (async)
        if exists('s:job')
            call jobstop(s:job)
        endif

        let s:job = jobstart(l:cmd, {
            \ 'on_stdout': {_c, m, _e -> s:IsortLineCallback(m)},
            \ 'on_exit': {_c, _m, _e -> s:IsortDoneCallback()},
            \ 'stdout_buffered': v:true,
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
            \ 'callback': {_, m -> s:IsortLineCallback([m])},
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
        execute a:start_line . ',' . a:end_line . '! isort -'
        call setpos('.', l:cursor_pos)

        " Done!
        if exists('s:callback')
            call s:callback()
        endif
    endif
endfunction
