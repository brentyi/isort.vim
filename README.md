# Async isort plugin for Vim + Neovim

A lighter, pure-Vimscript version of fisadev's wonderful
[vim-isort](https://github.com/fisadev/vim-isort) plugin, which (a) solves some
performance + virtual env issues and (b) adds automatic detection for
first-party package names by searching parent directories for a `setup.py` file.

Similar to:

```
command! -range=% Isort :<line1>,<line2>! isort -
```

But faster, without the annoying cursor jump, and with isort's `--project` flag
automatically specified.

Designed to run asynchronously in Vim 8 + Neovim, but also backward-compatible
with older versions of Vim.

## Installation

- Install [isort](https://github.com/timothycrosley/isort) via pip:

  ```bash
  pip install isort
  ```

- Install `isort.vim` in your `.vimrc` via your favorite plugin manager; I use
  `vim-plug`:

  ```vimscript
  Plug 'brentyi/isort.vim'
  ```

## Usage

`:Isort` will sort all imports of a file in normal mode, or a range of lines in
visual mode.

Mappings are left to the user. One possibility:

```
augroup IsortMappings
    autocmd!
    autocmd FileType python nnoremap <buffer> <Leader>si :Isort<CR>
    autocmd FileType python vnoremap <buffer> <Leader>si :Isort<CR>
augroup END
```

We can also add a callback function via the
`isort#Isort(startline, endline, callback)` function. For example, one option is
to use [vim-codefmt](https://github.com/google/vim-codefmt) to format after
sorting:

```
call isort#Isort(1, line('$'), function('codefmt#FormatBuffer'))
```

## Configuration

You can configure additional CLI
[arguments](https://pycqa.github.io/isort/docs/configuration/options/) for
`isort` via `g:isort_vim_options`:

```vimscript
let g:isort_vim_options = '-l 120 --wl 100 -m 2 --case-sensitive'
```

Here's an example for following formatting standards enforced by
[black](https://github.com/psf/black), ported from
[here](https://black.readthedocs.io/en/stable/compatible_configs.html#isort):

```vimscript
let g:isort_vim_options = join([
	\ '--multi-line 3',
	\ '--trailing-comma',
	\ '--force-grid-wrap 0',
	\ '--use-parentheses',
	\ '--ensure-newline-before-comments',
	\ '--line-length 88',
	\ ], ' ')
```
