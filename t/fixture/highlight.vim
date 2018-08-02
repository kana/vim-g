command! G echo "G"
" Not failed {{{1
function! G()
  return "G"
endfunction
" Failed "{{{1
command! G echo "G"
function! G()
  return "G"
endfunction
