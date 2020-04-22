function! isort#IsortLines(startline, endline)

    " Original implementation
    " Slower for whatever reason :/
    " > let l:cursor_pos = getpos('.')
    " > execute a:startline . ',' . a:endline . '! isort -'
    " > call setpos('.', l:cursor_pos)

    let l:file_contents = join(getline(a:startline, a:endline), "\n")
    let l:result = system('isort -', l:file_contents)
    if v:shell_error != 0
        " Command failed!
        return
    endif
    let l:formatted_lines = split(l:result, '\n')

    " Add some extra lines if our output is longer than our input
    let l:endline = a:endline
    while len(l:formatted_lines) - 1 > l:endline - a:startline
        call append(l:endline, "")
        let l:endline += 1
    endwhile

    " Set lines from isort
    call setline(a:startline, l:formatted_lines)

    " Delete any extra lines if we've shortened our buffer
    if a:startline + len(l:formatted_lines) <= l:endline
        let l:cursor_pos = getpos('.')
        execute (a:startline + len(l:formatted_lines)) . ',' . l:endline . 'd _'
        call setpos('.', l:cursor_pos)
    endif
endfunction
