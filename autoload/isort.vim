function! s:IsortLineCallback(formatted_lines)
    let l:formatted_lines = a:formatted_lines
    if s:start_line + s:line_counter <= s:end_line
        " Modify existing lines
        if exists("*setbufline")
            " We compare against the current contents to avoid needlessly
            " setting the file modified flag
            let l:current_lines = getbufline(
                \ s:target_buffer,
                \ s:start_line + s:line_counter,
                \ s:start_line + s:line_counter + len(l:formatted_lines) - 1)
            if string(l:current_lines) !=# string(l:formatted_lines)
                call setbufline(s:target_buffer, s:start_line + s:line_counter, l:formatted_lines)
            endif
        else
            " We compare against the current contents to avoid needlessly
            " setting the file modified flag
            let l:current_lines = getline(
                \ s:start_line + s:line_counter,
                \ s:start_line + s:line_counter + len(l:formatted_lines) - 1)
            if string(l:current_lines) !=# string(l:formatted_lines)
                call setline(s:start_line + s:line_counter, l:formatted_lines)
            endif
        endif
    else
        " Add a new line
        echom string(l:formatted_lines)
        if exists("*appendbufline")
            call appendbufline(s:target_buffer, s:end_line, l:formatted_lines)
        else
            call append(s:end_line, l:formatted_lines)
        endif
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
        if exists("*deletebufline")
            call deletebufline(s:target_buffer, s:start_line + s:line_counter, s:end_line)
        else
            execute (s:start_line + s:line_counter) . ',' . s:end_line . 'd _'
        endif
        call setpos('.', l:cursor_pos)
    endif

    " Done!
    if exists('s:callback')
        sleep 1m " Hack for making sure all changes are flushed
        call s:callback()
    endif
endfunction

" Helper for finding first-party packages: recursively searches the directory
" tree upward for a `setup.py` file
function! s:FindFirstPartyPackageName(path)
    " Base case: return 0 to indicate failure
    if a:path == '/'
        return ''
    endif

    " Recursively search for a package, marked by a `setup.py` file
    if filereadable(a:path . '/setup.py')
        " Found setup.py!
        return fnamemodify(a:path, ':t')
    else
        " Keep trying
        return s:FindFirstPartyPackageName(fnamemodify(a:path, ':h'))
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
    let s:target_buffer = bufnr("%")

    " Accept callback
    if a:0 == 1
        let s:callback = a:1
    elseif exists('s:callback')
        unlet s:callback
    endif

    let l:cmd = 'isort -'

    " Find and add first-party package flag
    let l:known_first_party = s:FindFirstPartyPackageName(expand('%:p'))
    if l:known_first_party != ''
        let l:cmd .= ' --project ' . l:known_first_party
    endif

    " Add global options
    if exists('g:isort_vim_options')
        let l:cmd .= ' ' . g:isort_vim_options
    endif

    " Start job
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
        execute a:start_line . ',' . a:end_line . '! ' . l:cmd
        call setpos('.', l:cursor_pos)

        " Done!
        if exists('s:callback')
            call s:callback()
        endif
    endif
endfunction
