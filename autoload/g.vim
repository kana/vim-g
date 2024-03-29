" g - Misc. Git utilities
" Version: 1.2.0
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

function! g#_cmd_G(subcommand, ...)
  if a:subcommand ==# 'args'
    call g#args#_cli(a:000)
  elseif a:subcommand ==# 'blame'
    call g#blame#_cli()
  else
    call g#_fail('g: Unknown subcommand: ' . string(a:subcommand))
  endif
endfunction

function! g#_cmd_G_complete(a, l, p)
  let tokens = split(a:l, ' \+', v:true)
  if len(tokens) >= 3
    return []
  endif

  return filter([
  \   'args',
  \   'blame',
  \ ], {_, val -> stridx(val, tokens[1]) == 0})
endfunction

function! g#_fail(message)
  echohl ErrorMsg
  echo a:message
  echohl None
endfunction

" __END__
" vim: foldmethod=marker
