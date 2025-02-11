" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_project_tray#🗂
" License: GPLv3 / Copyright © 2024 Landon Bouma.

" -------------------------------------------------------------------

" I wish this were more responsive!
function! g:embrace#vresize#VerticalResizeNormalBufferWindowsEqually() abort
  let l:old_win = winnr()

  let l:avail_cols = 0
  let l:normal_wins = []

  let l:cur_win = 1
  let l:prev_win = 0

  execute l:cur_win .. 'wincmd w'

  while l:prev_win != l:cur_win
    let l:prev_win = l:cur_win

    let l:cur_buf = winbufnr(l:cur_win)

    if g:embrace#windows#IsNormalBuffer(l:cur_buf)
      let l:avail_cols += winwidth(l:cur_win)

      call add(l:normal_wins, l:cur_win)

      " echom 'Normal buffer: l:avail_cols: ' .. l:avail_cols
    endif

    " See |CTRL-W_l|
    wincmd l

    let l:cur_win = winnr()

    " echom 'Next window: l:cur_win: ' .. l:cur_win
  endwhile

  let l:num_normal = len(l:normal_wins)

  if l:num_normal > 1
    let l:avg_width = str2nr(l:avail_cols / l:num_normal)

    let l:num_wins = len(l:normal_wins)
    let l:cur_num = 0

    for l:cur_win in l:normal_wins
      " Skip last window
      if (l:cur_num + 1) < l:num_wins
        " echom 'l:cur_win: ' .. l:cur_win .. ' / vertical resize: ' .. l:avg_width

        " Doesn't seem to make a different in performance.
        if 0
          execute l:cur_win .. 'wincmd w'

          exec 'vertical resize ' .. l:avg_width
        else
          exec l:cur_win . 'windo vertical resize ' .. l:avg_width
        endif
      endif
    endfor
  endif

  execute l:old_win .. 'wincmd w'
endfunction

