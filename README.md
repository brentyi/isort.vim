# Async isort plugin for Vim + Neovim

A lighter, pure-Vimscript version of fisadev's wonderful
[vim-isort](https://github.com/fisadev/vim-isort) plugin. Mostly written to
solve performance + virtual environment issues.

Equivalent to:

```
command! -range=% Isort :<line1>,<line2>! isort -
```

...but significantly faster & without the annoying cursor jump.

Designed to run asynchronously in Vim 8 + Neovim, but also backward-compatible
with older versions of Vim.

## Installation

- Install [isort](https://github.com/timothycrosley/isort) via pip:

  ```bash
  pip install isort
  ```

- Install `isort.vim` via your favorite plugin manager, eg vim-plug:
  ```vimscript
  Plug 'brentyi/isort.vim'
  ```

## Usage

`:Isort` will sort all imports of a file in normal mode, or a range of lines in
visual mode.

Mappings are left to the user. Here's what I use:

```
augroup IsortMappings
    autocmd!
    autocmd FileType python nnoremap <buffer> <Leader>si :Isort<CR>
    autocmd FileType python vnoremap <buffer> <Leader>si :Isort<CR>
augroup END
```

We can also add a callback function via the
`isort#Isort(startline, endline, callback)` function. For example, we can use
vim-codefmt to format after sorting:

```
call isort#Isort(1, line('$'), function('codefmt#FormatBuffer'))
```

## Configuration

You can configure isort's [arguments](https://pycqa.github.io/isort/docs/configuration/options/):

```vimscript
let g:isort_vim_options = '-l 120 --wl 100 -m 2 --case-sensitive'
```
