" g - Misc. Git utilities
" Version: 1.0.0
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

function! g#vc#_sid()
  return expand('<SID>')
endfunction

function! g#vc#add(...)
  return s:run_git('add', a:000)
endfunction

function! g#vc#restore(...)
  return s:run_git('restore', a:000)
endfunction

function! s:make_command_line(subcommand, args)
  return join(map(['git', a:subcommand] + a:args, {_, s -> shellescape(s, v:true)}))
endfunction

function! s:run_git(subcommand, args)
  let autowrite = &autowrite
  set noautowrite  " to avoid E676 for s:finish_commit().

  execute '!' s:make_command_line(a:subcommand, a:args)
  let success = v:shell_error == 0

  let &autowrite = autowrite
  return success
endfunction

" __END__
" vim: foldmethod=marker
