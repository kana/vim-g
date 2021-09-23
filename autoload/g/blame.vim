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

function! g#blame#_scope()
  return s:
endfunction

function! g#blame#_sid()
  return expand('<SID>')
endfunction

function! g#blame#_cli()
  if &l:buftype !=# ''
    return g#_fail('g: Only a normal buffer can be blamed')
  endif

  let bufname = bufname('')
  let output = system('git blame -- ' . shellescape(bufname))
  if v:shell_error != 0
    return g#_fail('g: ' . substitute(output, '[\r\n]*$', '', ''))
  endif

  let original_pos = getcurpos()
  let original_filetype = &l:filetype
  new
  let b:g_commit_ishes = ['HEAD']
  let b:g_filepaths = [fnamemodify(bufname, ':p:.')]
  let b:g_positions = [[bufnr('')] + original_pos[1:]]
  let b:g_undo_index = 0
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nowrap
  execute 'setfiletype' original_filetype
  syntax match gitBlameHeader /^\^\?\x\+ \%(\S\+ \+\)\?(.\{-} \d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d .\d\d\d\d \+\d\+)/ containedin=ALL
  highlight default link gitBlameHeader LineNr
  call s:blame_update_viewer_buffer_name()

  silent put =output
  1 delete _

  " Clear undo history to avoid undoing to nothing.
  let original_undolevels = &l:undolevels
  let &l:undolevels = -1
  execute 'normal!' "a \<BS>\<Esc>"
  let &l:undolevels = original_undolevels

  setlocal nomodifiable

  call setpos('.', b:g_positions[b:g_undo_index])
  normal! zz

  nnoremap <buffer> K :<C-u>call <SID>blame_show_this_commit()<CR>
  nnoremap <buffer> o :<C-u>call <SID>blame_dig_into_older_one()<CR>
  nnoremap <buffer> u :<C-u>call <SID>blame_undo()<CR>
  nnoremap <buffer> <C-r> :<C-u>call <SID>blame_redo()<CR>
endfunction

function! s:blame_update_viewer_buffer_name()
  let commit_ish = b:g_commit_ishes[b:g_undo_index]
  let filepath = b:g_filepaths[b:g_undo_index]
  let commit_ish_label = commit_ish ==# 'HEAD' ? '' : commit_ish . ' '
  silent file `=printf('[git blame] %s%s', commit_ish_label, filepath)`
endfunction

function! s:blame_show_this_commit()
  let commit_id = matchstr(getline('.'), '\v^\^?\zs\x+')
  if commit_id == ''
    return g#_fail('g: Cannot find the commit id for the current line')
  endif

  call s:.show(commit_id)
endfunction

function! s:.show(commit_id)
  execute '!git show' shellescape(a:commit_id)
endfunction

function! s:blame_dig_into_older_one()
  if getline('.') =~ '^\^'
    return g#_fail('g: There is no content older than the root commit')
  endif

  let matches = matchlist(getline('.'), '\v^(\x+) %((\S+) +)?\(')
  if matches == []
    return g#_fail('g: Cannot find the commit id for the current line')
  endif

  let commit_id = matches[1]
  let old_filepath = matches[2]
  if old_filepath == ''
    let old_filepath = b:g_filepaths[b:g_undo_index]
  endif

  let target_committish = commit_id . '~'
  let output = system('git blame -w ' . shellescape(target_committish) . ' -- ' . shellescape(old_filepath))
  if v:shell_error != 0
    return g#_fail('g: ' . substitute(output, '[\r\n]*$', '', ''))
  endif

  let before_commit_id = s:blame_find_latest_commit_from_blame_output(getline(1, '$'))
  let after_commit_id = s:blame_find_latest_commit_from_blame_output(split(output, '\n'))
  let diff = system('git diff -b ' . shellescape(after_commit_id) . '..' . shellescape(before_commit_id) . ' -- ' . shellescape(old_filepath))
  if v:shell_error != 0
    return g#_fail('g: ' . substitute(diff, '[\r\n]*$', '', ''))
  endif
  let pos = s:blame_guess_logical_cursor_position(diff, getcurpos())

  let b:g_commit_ishes = b:g_commit_ishes[:b:g_undo_index] + [target_committish]
  let b:g_filepaths = b:g_filepaths[:b:g_undo_index] + [old_filepath]
  let b:g_positions = b:g_positions[:b:g_undo_index] + [pos]
  let b:g_undo_index += 1
  call s:blame_update_viewer_buffer_name()

  setlocal modifiable
  % delete _
  silent put =output
  1 delete _
  setlocal nomodifiable

  call setpos('.', pos)
  normal! zz
endfunction

function! s:blame_find_latest_commit_from_blame_output(blame_lines)
  let lines = map(a:blame_lines, {_, v -> substitute(v, '^^\?\(\x\+\).\{-} (.* \(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\) .*$', '\2\t\1', '')})
  call sort(lines)
  return split(lines[-1], '\t')[1]
endfunction

function! s:blame_guess_logical_cursor_position(diff, pos)
  " -----------------------------
  " commit ...
  " Author: ...
  " Date: ...
  "
  "     Subject...
  "
  " diff --git a/... b/...
  " index aaaaaaa..bbbbbbb 100644
  " --- a/...
  " +++ b/...
  " @@ -3,7 +3,7 @@
  "  ...
  " -...
  " +...
  "  ...
  " @@ -13,17 +13,17 @@
  "  ...
  " -...
  " +...
  " +...
  "  ...
  " @@ ... @@
  " ...
  " -----------------------------
  "               |
  "               V
  " -----------------------------
  " @@ -3,7 +3,7 @@
  "  ...
  " -...
  " +...
  "  ...
  " -----------------------------
  "               +
  " -----------------------------
  " @@ -13,17 +13,17 @@
  "  ...
  " -...
  " +...
  " +...
  "  ...
  " -----------------------------
  "               +
  "               :
  let blocks = split(a:diff, '\v(^|\n)\zs\ze\@\@')[1:]

  " Find a right diff block.
  let original_line = a:pos[1]
  let found_block = 0
  for block in blocks
    let matches = matchlist(block, '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\)')
    let [old_base, old_count, new_base, new_count] = matches[1:4]
    if new_base <= original_line && original_line < new_base + new_count
      let found_block = block
    endif
  endfor
  if found_block is 0
    " Might be better to show an error message,
    " though this case is unlikely to occur.
    return a:pos
  endif

  " Find a series of changed lines which includes the original line.
  let old_line = old_base - 1
  let new_line = new_base - 1
  let importantly_added_line_count = 0
  let importantly_deleted_line_count = 0
  let totally_added_line_count = 0
  let totally_deleted_line_count = 0
  let found_changed_lines = v:false
  for diff_line in split(block, '\n', !0)[1:]
    if diff_line[0] ==# '+'
      let new_line += 1
      let importantly_added_line_count += 1
      let totally_added_line_count += 1
      if new_line == original_line
        let found_changed_lines = v:true
      endif
    elseif diff_line[0] ==# '-'
      let old_line += 1
      let importantly_deleted_line_count += 1
      let totally_deleted_line_count += 1
    else
      if found_changed_lines
        break
      endif
      let new_line += 1
      let old_line += 1
      let importantly_added_line_count = 0
      let importantly_deleted_line_count = 0
    endif
  endfor

  " Guess the line number for the old content from the changed lines.
  let guessed_pos = copy(a:pos)
  let guessed_pos[1] =
  \   original_line
  \ + (old_base - new_base)
  \ + (importantly_deleted_line_count - importantly_added_line_count) / 2
  \ + ((totally_deleted_line_count - importantly_deleted_line_count)
  \    - (totally_added_line_count - importantly_added_line_count))
  return guessed_pos
endfunction

function! s:blame_undo()
  if b:g_undo_index == 0
    return
  endif
  let b:g_undo_index -= 1
  call s:blame_update_viewer_buffer_name()

  setlocal modifiable
  undo
  setlocal nomodifiable

  call setpos('.', b:g_positions[b:g_undo_index])
  normal! zz
endfunction

function! s:blame_redo()
  if b:g_undo_index == len(b:g_filepaths) - 1
    return
  endif
  let b:g_undo_index += 1
  call s:blame_update_viewer_buffer_name()

  setlocal modifiable
  redo
  setlocal nomodifiable

  call setpos('.', b:g_positions[b:g_undo_index])
  normal! zz
endfunction

" __END__
" vim: foldmethod=marker
