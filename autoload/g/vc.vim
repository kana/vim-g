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

function! g#vc#_sid()
  return expand('<SID>')
endfunction

function! g#vc#add(...)
  return s:run_git('add', a:000)
endfunction

function! g#vc#commit(...)
  return s:open_command_buffer('gitcommit', 'commit', a:000)
  \ && s:set_up_commit_on_write_hook(a:000)
endfunction

function! g#vc#diff(...)
  return s:open_command_buffer('diff', 'diff', a:000)
endfunction

function! g#vc#restore(...)
  return s:run_git('restore', a:000)
endfunction

function! s:fetch_command_buffer_contents(subcommand, args)
  if a:subcommand ==# 'commit'
    " Check there are changes to commit.
    call system(s:make_command_line(['commit', '--dry-run'] + a:args))
    if v:shell_error != 0
      return []
    endif

    " Generate .git/COMMIT_EDITMSG.
    call system(s:make_command_line(['-c', 'core.editor=false', 'commit'] + a:args))
    return readfile(s:get_git_dir() .. '/COMMIT_EDITMSG')
  elseif a:subcommand ==# 'diff'
    return systemlist(s:make_command_line(['diff'] + a:args))
  else
    throw 'unreachable'
  endif
endfunction

function! s:get_git_dir()
  return trim(system('git rev-parse --git-dir'))
endfunction

function! s:make_command_buffer_name(subcommand, args)
  let i = 1
  while v:true
    let suffix = i == 1 ? [] : ['(' .. i .. ')']
    let bufname = join(['git', a:subcommand] + a:args + suffix)
    if !bufexists(bufname)
      return bufname
    endif
    let i += 1
  endwhile
endfunction

function! s:make_command_line(args)
  return join(map(['git'] + a:args, {_, s -> shellescape(s, v:true)}))
endfunction

function! s:open_command_buffer(filetype, subcommand, args)
  " Memoize the information to restore the current state in case of errors in
  " the following steps.
  let winrestcmd = winrestcmd()

  " Create a new buffer for the given command.
  let v:errmsg = ''
  silent! execute get(g:, 'g_vc_split_modifier', '') 'new'
  if v:errmsg != ''
    " Error message is already showed by Vim.
    return v:false
  endif

  let contents = s:fetch_command_buffer_contents(a:subcommand, a:args)
  if len(contents) == 0
    close
    execute winrestcmd
    echo 'There are no changes.'
    return v:false
  endif

  " Initialize the command buffer.
  setlocal bufhidden=wipe buftype=nofile noswapfile
  silent file `=s:make_command_buffer_name(a:subcommand, a:args)`
  silent put =contents
  1 delete _
  execute 'setfiletype' a:filetype

  return v:true
endfunction

function! s:run_git(subcommand, args)
  echo 'git' a:subcommand join(a:args)
  let output = system(s:make_command_line([a:subcommand] + a:args))
  let success = v:shell_error == 0
  if !success
    echohl ErrorMsg
    echo trim(output)
    echohl None
  endif
  return success
endfunction

function! s:set_up_commit_on_write_hook(args)
  setlocal buftype=acwrite nomodified
  let b:g_vc_args = a:args
  autocmd BufWriteCmd <buffer> call s:write_hook()
  return v:true
endfunction

function! s:write_hook()
  let file = s:get_git_dir() .. '/COMMIT_EDITMSG'
  silent write! `=file`
  let lines = (['commit', '-F', file, '--cleanup=strip'] + b:g_vc_args)
  \           ->s:make_command_line()->systemlist()
  if v:shell_error
    echohl ErrorMsg
    echo join(lines, "\n")
    echohl None
    return
  endif

  " git commit typically shows the following message after successful commit:
  "
  "     [{branch-name} {commit-id}] {commit-message}
  "      Date: {author-date}
  "      {L} file changed, {M} insertions(+), {N} deletions(-)
  "
  " Date line appears if --amend is used.
  echo lines[-1]
  bwipeout!
endfunction

" __END__
" vim: foldmethod=marker
