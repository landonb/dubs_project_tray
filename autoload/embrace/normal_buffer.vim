" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_project_tray#🗂
" License: GPLv3 / Copyright © 2024 Landon Bouma.

" -------------------------------------------------------------------

function! g:embrace#normal_buffer#IsNormalBuffer(bufnr) abort
  let l:bufnr = bufnr(a:bufnr)

  let l:ftype = getbufvar(l:bufnr, "&filetype")

  if 0
    \ || getbufvar(l:bufnr, '&buftype') != ''
    \ || getbufvar(l:bufnr, "&previewwindow")
    \ || !getbufvar(l:bufnr, "&modifiable")
    \ || !buflisted(l:bufnr)
    \ || l:ftype == 'qf'
    \ || l:ftype == 'git'
    \ || l:ftype == 'fugitiveblame'
    \ || bufname(l:bufnr) == '-MiniBufExplorer-'

    return 0
  endif

  return 1
endfunction

" -------------------------------------------------------------------

