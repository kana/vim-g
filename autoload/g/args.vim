" g - Misc. Git utilities
" Version: 1.1.0
" Copyright (C) 2018-2021 Kana Natsuno <https://whileimautomaton.net/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

function! g#args#_cli(patterns)
  if len(a:patterns) == 0
    return g#_fail('g: Specify at least one pattern.')
  endif

  let shell_args = map(copy(a:patterns), {_, val -> s:normalize_pattern(val)})
  let files = systemlist('git ls-files ' .. join(shell_args))
  if len(files) == 0
    return g#_fail('g: Nothing matched.')
  endif

  execute 'args' join(files)
endfunction

function! s:normalize_pattern(pattern)
  if a:pattern =~# '^''.*''$'
    return a:pattern
  endif

  return substitute(a:pattern, '\v^\*?(.{-})\*?$', '''*\1*''', '')
endfunction

" __END__
" vim: foldmethod=marker
