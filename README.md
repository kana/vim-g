# vim-g [![CI](https://github.com/kana/vim-g/actions/workflows/ci.yml/badge.svg)](https://github.com/kana/vim-g/actions/workflows/ci.yml)

This is a Vim plugin which provides misc. utilities for Git.

# Features

## `:G args {pattern} [{pattern}...]`

Like `:args`, but {pattern}s are interpreted by Git.

Usage examples:

- `G args 'tests/*.php'` for all PHP files under `tests/`.
- `G args SomeComponent` for all files which paths includes `SomeComponent`.
   Like all `*.ts` and `*.tsx` files under `components/SomeComponent/`.

## `:G blame`

Open a Git blame viewer for the current buffer.

You can dig into blame prior to the change on the cursor line by typing `o`,
and rewind the state by typing `u`.

## `g#branch#get_name({dir})`

Return the current branch name.  Useful for options like `'tabline'`.

It detects detached HEAD state and returns special notation in that case.  For
example,

- `REBASE-i` in the middle of `git rebase -i`
- `master~100` if you intentionally did `git checkout master~100` to
  investigate a problem

## `g#vc#add()` `g#vc#commit()` `g#vc#diff()` `g#vc#restore()`

Wrappers for the corresponding Git subcommands.  Useful to define key mappings
for frequent usage.  For example:

```vim
" Open a new buffer to edit commit message.
" :write the buffer to commit all modified files.
nnoremap <Leader>vC <Cmd>call g#vc#commit('-av')<CR>
```

```vim
" Open a new buffer to review all uncomitted changes.
nnoremap <Leader>vD <Cmd>call g#vc#diff('HEAD', '--', '.')<CR>
```

```vim
" Revert unstaged changes in the current file.
nnoremap <Leader>vv <Cmd>call g#vc#restore(expand('%'))<CR>
```

# Further reading

See [doc/g.txt](./doc/g.txt).
