# isort.vim

Plugin for sorting Python imports in Vim and Neovim via `isort`. Inspired by
[fisadev/vim-isort](https://github.com/fisadev/vim-isort), but with a few
differentiating features:

- Written in VimScript instead of Python: this is faster, less sensitive to
  virtual environment issues, and runs on vim builds without the `+python`
  feature.
- Adds automatic detection for first-party package names, by searching parent
  directories for `setup.py` or `pyproject.toml` files.
- Attempts to be minimally obtrusive: runs asynchronously where possible, with
  support for both Vim 8 and Neovim's job APIs.

---

<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Alternatives](#alternatives)

<!-- vim-markdown-toc -->

## Installation

- Install [isort](https://github.com/timothycrosley/isort) via pip:

  ```bash
  pip install isort
  ```

- Install `isort.vim` in your `.vimrc` via your favorite plugin manager, for
  example, `vim-plug`:

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

More advanced usage is possible with the
`isort#Isort(startline, endline, [callback, [enable_async]])` function. For example, one option is
to use [vim-codefmt](https://github.com/google/vim-codefmt) to format after
sorting:

```
:call isort#Isort(1, line('$'), function('codefmt#FormatBuffer'))
```

Disabling async sorting is helpful for sorting automatically before saving:

```vimscript
autocmd BufWritePre *.py call isort#Isort(0, line('$'), v:null, v:false)
```

## Configuration

[Additional CLI arguments for isort](https://pycqa.github.io/isort/docs/configuration/options/)
can be configured via `g:isort_vim_options`:

```vimscript
let g:isort_vim_options = '-l 120 --wl 100 -m 2 --case-sensitive'
```

Here's an example for following formatting standards enforced by
[black](https://github.com/psf/black), ported from
[the isort documentation](https://black.readthedocs.io/en/stable/guides/using_black_with_other_tools.html#isort):

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

Or, assuming `isort>=5.0.0`, simply:

```vimscript
let g:isort_vim_options = '--profile black'
```

## Alternatives

- [fisadev/vim-isort](https://github.com/fisadev/vim-isort) is the original
  isort plugin for Vim, and the primary inspiration for ours.

- [google/vim-codefmt](https://github.com/google/vim-codefmt) has basic support
  for `isort` as a code formatter.

- If you don't need bells and whistles or mind a cursor jump each time you sort
  imports, a rudimentary `:Isort` command can be trivially implemented:

  ```
  command! -range=% Isort :<line1>,<line2>! isort -
  ```
