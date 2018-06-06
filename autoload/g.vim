" g - Git stuffs
" Version: 0.0.0
" Copyright (C) 2018 Kana Natsuno <https://whileimautomaton.net/>
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
function! g#_scope()  "{{{1
  return s:
endfunction

function! g#_cmd_G(subcommand, ...)  "{{{1
  if a:subcommand ==# 'blame'
    call s:blame()
  else
    call s:fail('g: Unknown subcommand: ' . string(a:subcommand))
  endif
endfunction

function! s:blame()  "{{{1
  if &l:buftype !=# ''
    return s:fail('g: Only a normal buffer can be blamed')
  endif

  let bufname = bufname('')
  let output = system('git blame -- ' . shellescape(bufname))
  if v:shell_error != 0
    return s:fail('g: ' . substitute(output, '[\r\n]*$', '', ''))
  endif

  new
  let b:g_commit_ishes = ['HEAD']
  let b:g_filepaths = [fnamemodify(bufname, ':p:.')]
  let b:g_undo_index = 0
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nowrap
  call s:blame_update_viewer_buffer_name()

  silent put =output
  1 delete _

  " Clear undo history to avoid undoing to nothing.
  let original_undolevels = &l:undolevels
  let &l:undolevels = -1
  execute 'normal!' "a \<BS>\<Esc>"
  let &l:undolevels = original_undolevels

  setlocal nomodifiable

  nnoremap <buffer> K  :<C-u>call <SID>blame_show_this_commit()<Return>
  nnoremap <buffer> o  :<C-u>call <SID>blame_dig_into_older_one()<Return>
  nnoremap <buffer> u  :<C-u>call <SID>blame_undo()<Return>
  nnoremap <buffer> <C-r>  :<C-u>call <SID>blame_redo()<Return>
  " TODO: Syntax highlighting.
endfunction

function! s:blame_update_viewer_buffer_name() "{{{2
  let commit_ish = b:g_commit_ishes[b:g_undo_index]
  let filepath = b:g_filepaths[b:g_undo_index]
  let commit_ish_label = commit_ish ==# 'HEAD' ? '' : commit_ish . ' '
  silent file `=printf('[git blame] %s%s', commit_ish_label, filepath)`
endfunction

function! s:blame_show_this_commit()  "{{{2
  let commit_id = matchstr(getline('.'), '\v^\x+')
  if commit_id == ''
    return s:fail('g: Cannot find the commit id for the current line')
  endif

  call s:.show(commit_id)
endfunction

function! s:.show(commit_id)
  execute '!git show' shellescape(a:commit_id)
endfunction

function! s:blame_dig_into_older_one()  "{{{2
  let matches = matchlist(getline('.'), '\v^(\x+) %((\S+) +)?\(')
  if matches == []
    return s:fail('g: Cannot find the commit id for the current line')
  endif

  let commit_id = matches[1]
  let old_filepath = matches[2]
  if old_filepath == ''
    let old_filepath = b:g_filepaths[b:g_undo_index]
  endif

  " TODO: Keep the "logical" cursor position.
  " -- Parse `git show -b commit_id old_filepath`, then locate the cursor at
  "    the line just before the newly added lines in the commit.
  let pos = getpos('.')

  let target_committish = commit_id . '~'
  let output = system('git blame -w ' . shellescape(target_committish) . ' -- ' . shellescape(old_filepath))
  if v:shell_error != 0
    return s:fail('g: ' . substitute(output, '[\r\n]*$', '', ''))
  endif

  let b:g_commit_ishes = b:g_commit_ishes[:b:g_undo_index] + [target_committish]
  let b:g_filepaths = b:g_filepaths[:b:g_undo_index] + [old_filepath]
  let b:g_undo_index += 1
  call s:blame_update_viewer_buffer_name()

  setlocal modifiable
  % delete _
  silent put =output
  1 delete _
  setlocal nomodifiable

  call setpos('.', pos)
endfunction

function! s:blame_undo()  "{{{2
  if b:g_undo_index == 0
    return
  endif
  let b:g_undo_index -= 1
  call s:blame_update_viewer_buffer_name()

  " TODO: Keep the cursor position after undo.
  setlocal modifiable
  undo
  setlocal nomodifiable
endfunction

function! s:blame_redo()  "{{{2
  if b:g_undo_index == len(b:g_filepaths) - 1
    return
  endif
  let b:g_undo_index += 1
  call s:blame_update_viewer_buffer_name()

  " TODO: Keep the cursor position after redo.
  setlocal modifiable
  redo
  setlocal nomodifiable
endfunction

function! g#get_branch_name(dir)  "{{{1
  let cache_entry = get(s:branch_name_cache, a:dir, 0)
  if cache_entry is 0
  \  || cache_entry[1] !=# s:branch_name_cache_key(a:dir)
    unlet cache_entry
    let cache_entry = s:get_branch_name_and_cache_key(a:dir)
    let s:branch_name_cache[a:dir] = cache_entry
  endif

  return cache_entry[0]
endfunction

" {[key: dir_path]: [branch_name, cache_key]}  "{{{2
let s:branch_name_cache = {}

function! s:branch_name_cache_key(dir)  "{{{2
  return getftime(a:dir . '/.git/HEAD') . getftime(a:dir . '/.git/MERGE_HEAD')
endfunction

function! s:get_branch_name_and_cache_key(dir)  "{{{2
  let git_dir = a:dir . '/.git'

  if isdirectory(git_dir)
    if isdirectory(git_dir . '/rebase-apply')
      if filereadable(git_dir . '/rebase-apply/rebasing')
        let additional_info = 'REBASE'
      elseif filereadable(git_dir . '/rebase-apply/applying')
        let additional_info = 'AM'
      else
        let additional_info = 'AM/REBASE'
      endif
      let head_info = s:first_line(git_dir . '/HEAD')
    elseif filereadable(git_dir . '/rebase-merge/interactive')
      let additional_info = 'REBASE-i'
      let head_info = s:first_line(git_dir . '/rebase-merge/head-name')
    elseif isdirectory(git_dir . '/rebase-merge')
      let additional_info = 'REBASE-m'
      let head_info = s:first_line(git_dir . '/rebase-merge/head-name')
    elseif filereadable(git_dir . '/MERGE_HEAD')
      let additional_info = 'MERGING'
      let head_info = s:first_line(git_dir . '/HEAD')
    else  " Normal case
      let additional_info = ''
      let head_info = s:first_line(git_dir . '/HEAD')
    endif

    let branch_name = matchstr(head_info, '^\(ref: \)\?refs/heads/\zs\S\+\ze$')
    if branch_name == ''
      let lines = readfile(git_dir . '/logs/HEAD')
      let co_lines = filter(lines, 'v:val =~# "checkout: moving from"')
      let log = empty(co_lines) ? '' : co_lines[-1]
      let branch_name = substitute(log, '^.* to \([^ ]*\)$', '\1', '')
      if branch_name == ''
        let branch_name = '(unknown)'
      endif
    endif
    if additional_info != ''
      let branch_name .= ' ' . '(' . additional_info . ')'
    endif
  else  " Not in a git repository.
    let branch_name = '-'
  endif

  return [branch_name, s:branch_name_cache_key(a:dir)]
endfunction

function! s:first_line(file)  "{{{2
  let lines = readfile(a:file, '', 1)
  return 1 <= len(lines) ? lines[0] : ''
endfunction

function! s:fail(message)  "{{{1
  echohl ErrorMsg
  echo a:message
  echohl None
endfunction

" __END__  "{{{1
" vim: foldmethod=marker
