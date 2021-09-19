# vim-g [![CI](https://github.com/kana/vim-g/actions/workflows/ci.yml/badge.svg)](https://github.com/kana/vim-g/actions/workflows/ci.yml)

This is a Vim plugin which provides misc. utilities for Git.

## `:G blame`

This command opens a Git blame viewer for the current buffer.
The viewer provides the following keyboard shortcuts (defined in Normal mode):

| Keys   | Action                                                           |
| ------ | ---------------------------------------------------------------- |
| `K`    | `git show` the commit corresponding to the cursor line.          |
| `o`    | View blame prior to the commit corresponding to the cursor line. |
| `u`    | Undo `o`.                                                        |
| `<C-r>`| Redo `o`.                                                        |

## `g#branch#get_name()`

This function returns the name of the current "branch".  It detects detached
HEAD state and returns special notation in that case.  For example, `REBASE-i`
in the middle of `git rebase -i`.

Useful for `'tabline'`.
