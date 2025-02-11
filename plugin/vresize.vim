" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_project_tray#🗂
" License: vim-buffer-delights by Landon Bouma is marked with CC0 1.0
"   https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2024 Landon Bouma.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_dubs_project_tray_vresize
endif

if exists('g:loaded_dubs_project_tray_vresize') || &cp

  finish
endif

let g:loaded_dubs_project_tray_vresize = 1

" -------------------------------------------------------------------

if get(g:, 'dubs_project_tray_disable', 0)

  finish
endif

" -------------------------------------------------------------------

command! -nargs=* ResizeEvenlyV call g:embrace#vresize#VerticalResizeNormalBufferWindowsEqually()

