" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/> 
" Project: https://github.com/landonb/dubs_project_tray#🗂
" License: GPLv3 | Copyright © 2009, 2015-2017 Landon Bouma.
" Summary: Enhanced Project Plugin

" -------------------------------------------------------------------

" FIXME: On first boot, make the project template.
"        E.g.,
"
"         command cp \
"           ~/.kit/nvim/landonb/start/dubs_project_tray/.vimprojects.template \
"           ~/.kit/nvim/landonb/start/dubs_project_tray/.vimprojects
"
"       and tell user to move to private location
"       and to create a symlink in project root.
"
"       - Or, just document in the readme and call it, 'good'.
"
"       - For an example of copying the template, see how
"           dubs_projects.vim.template
"         is copied by `LoadUsersGrepProjects` in:
"           ~/.kit/nvim/landonb/start/dubs_grep_steady/plugin/dubs_grep_steady.vim

" -------------------------------------------------------------------
" About/Usage
" -------------------------------------------------------------------

" See :help dubs-project-tray.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:plugin_dubs_project_tray
endif

if exists('g:plugin_dubs_project_tray') || &cp

  finish
endif

let g:plugin_dubs_project_tray = 1

" -------------------------------------------------------------------

" -------------------------------------------------------------------
" Alt-Shift-4 // Toggle Project Browser
" -------------------------------------------------------------------
" DubsProjectTray_ToggleProject_Wrapper
" -------------------------------------------------------------------

" Set the default project window width.
" - Some widths that've been tried in the past: 30, 3, 36, 39
let g:proj_window_width = get(g:, 'proj_window_width', 33)

" Remove the 'b' project flag, which uses browse() when handling the
" \C command. Problem is, you cannot select a directory (because it
" opens the directory instead), so use a simple edit box instead.
" - Default was 'imstb'.
let g:proj_flags='imst'

" ***

" FTREQ: Here are elsewhere, use g:vars to control bindings.
" - Another option is to skip a binding if already bound, e.g.,
"   if !hasmapto('<Plug>DubsProjectTray_ToggleProject_Wrapper')

" SYNC_ME: Dubs Vim's <M-????> mappings are spread across plugins. [M-S-4]
function! s:mappings_toggle_project_wrapper()
  " Note that nnoremap and inoremap won't work because <Plug> mapping.
  if has('macunix')
    nnoremap <silent> › <Plug>DubsProjectTray_ToggleProject_Wrapper
    inoremap <silent> › <C-O><Plug>DubsProjectTray_ToggleProject_Wrapper
  else
    nnoremap <silent> <M-$> <Plug>DubsProjectTray_ToggleProject_Wrapper
    inoremap <silent> <M-$> <C-O><Plug>DubsProjectTray_ToggleProject_Wrapper
  endif
  " Regarding of previous bindings, always create the Plug map.
  " - This makes the command externally callable, which allows
  "   other plugins to toggle the project tray.
  nnoremap <silent> <unique> <script>
    \ <Plug>DubsProjectTray_ToggleProject_Wrapper
    \ :call <SID>ToggleProject_Wrapper()<CR>
endfunction

call <SID>mappings_toggle_project_wrapper()

" ***

" After Project() is used to setup the project buffer, we must use
" ToggleProject thereafter, unless the project buffer is :bwipeout.
" - Project() complains when called again and project buffer exists.
" - REFER: g:proj_running

let s:vimprojs_fname = '.vimprojects'

function! s:ToggleProject_Wrapper()
  " Use mkview/loadview to store current view, i.e., to maintain
  " current folds (otherwise Vim resets them when you reenter buffer).
  " NOTE: Use silent to avoid 'E35: No file name' warning message.
  silent! mkview

  let save_winnr = winnr()

  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " the Project adds itself as the first window, so
    " we need to increase winnr by 1 to find our current
    " window again
    let save_winnr = save_winnr + 1
    if exists('g:proj_running')
      " After we set the .vimprojects path, we can stick
      " to using toggle to show and hide the project tray.
      " In fact, we cannot call Project(some_path) again
      " because it'll complain that it's already loaded.
      " Indeed, if you look at the Project plugin, you'll
      " see that it's one big singleton, kind of like a
      " JavaScript function that's a class that contains
      " all its methods as member variables -- the Project
      " function is setup once as a closure and then you
      " cannot re-initialize it or make a new one (though
      " there might be a way to clobber the old one, but
      " I'm not sure; and if there was a way, we'd probably
      " lose our cursor position in the buffer, which is
      " undesireable).
      execute 'ToggleProject'
    else
      let try_file = ''
      if exists('g:vimprojects_file')
        let try_file = g:vimprojects_file
      endif
      if (try_file == '') && filereadable($HOME . '/' . s:vimprojs_fname)
        " By default, Project opens ~/.vimprojects.
        execute 'ToggleProject'
      else
        let l:projf = ''
        if (try_file != '') && filereadable(try_file)
          let l:projf = try_file
        else
          " The project file is not at ~/.vimprojects.
          " - Rummage through user's &runtimepath.

          " Soooooo slow:
          "   let projf = findfile('.vimprojects', pathogen#split(&rtp)[0] . '/**')

          for vim_dir in pathogen#split(&rtp)
            let try_file = vim_dir . '/' . s:vimprojs_fname
            if filereadable(try_file)
              let l:projf = try_file
              break
            endif
          endfor
        endif

        if l:projf != ''
          " Weird: If we call the fcn. directly, e.g., `Project(l:projf)`
          "        then the Project function's variable is assigned the value
          "        l:projf (the *name* of the variable we're passing!). So
          "        we have to convert to a string first and use execute.
          execute 'Project ' . l:projf
          " Tell the user if they've got multiple project files.

          " Hey slow poke:
          "   let l:fcnt2 =
          "     \ findfile(s:vimprojs_fname, pathogen#split(&rtp)[0] . '/**', -1)
          let l:fcnt = 0
          for vim_dir in pathogen#split(&rtp)
            let try_file = vim_dir . '/' . s:vimprojs_fname
            if filereadable(try_file)
              let l:fcnt = l:fcnt + 1
            endif
          endfor

          if l:fcnt > 1
            " This plugin has its own .vimprojects file, which I want
            " to leave, so, well... ignore the warning. Also, findfile
            " follows symlinks, so it could just as well find .vimprojects
            " files in source code outside of the ~/.vim folder.
            "   call confirm('Warning: found ' . l:fcnt
            "                \ . ' ' . s:vimprojs_fname . ' files.', 'OK')
            echomsg 'Found ' . l:fcnt . ' ' . s:vimprojs_fname . ' files.'
          endif
        else
          call confirm('dubs: Cannot find ' . s:vimprojs_fname . ' file.', 'OK')
        endif
      endif
    endif
  else
    " Otherwise, we're losing the first window, so
    " compensate for the loss by subtracting one
    let save_winnr = save_winnr - 1
    " Clear the project buffer
    "execute bufwinnr(g:proj_running) . 'wincmd w'
    "bwipeout
    "
    execute 'ToggleProject'
    " 2011.06.14: This is what ToggleProject does:
    "let g:proj_mywindow = winnr()
    "Project
    "hide
    "if(winnr() != g:proj_mywindow)
    "  wincmd p
    "endif
    "unlet g:proj_mywindow
  endif
  "execute 'ToggleProject'
  " FIXME This behaviour does not belong here: Use Alt key modifier or another
  "       key combo to close all folds but the first and jump to the top,
  "       otherwise, save the position the user was at, which supports the
  "       work flow method of C-S-4'ing to see the list of files, opening a
  "       file, and then closing the sidebar.
  "if exists('g:proj_running') && bufwinnr(g:proj_running) == 1
  "  " Collapse all folds
  "  execute 'normal ' . 'zM'
  "  " Return to top of window
  "  execute 'normal ' . 'gg'
  "  " Jump to first fold ...
  "  execute 'normal ' . 'zj'
  "  " ... and open it
  "  execute 'normal ' . 'zA'
  "  " Now when the user closes the first fold, all others are visible
  "endif

  " 2011.01.15 On my laptop, I can't have the project window open and also
  "            look at two buffers side-by-side with at least 80 columns each,
  "            unless if I dismiss the project window. But that messes up the
  "            widths of my windows. Hence, we do a little dance.
  "
  " First, see how many columns we have to work with.
  let l:cols_avail = &columns
  if exists('g:proj_running') && bufwinnr(g:proj_running) == 1
    let l:cols_avail = l:cols_avail - g:proj_window_width
  endif
  "
  " Next, see if two buffers are open, and figure out which windows they're in.
  " Hint: the way dubs_project_tray sets it up, the Project window (file browser)
  " is on the left, and the buffer explorer and quickfix window are on the bottom.
  " That leaves one or two windows that the user is editing in the upper-right.
  " If there are two windows, they're either side-by-side or stacked depending
  " on how much room is available.
  let l:winnr_lhs = 0
  let l:winnr_rhs = 0
  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " The project window is not showing, so the user's windows are the first
    " and maybe the second window (since Vim numbers windows 1, 2, 3, ..., from
    " left to right and top to bottom
    if ( (0 == <SID>IsWindowSpecial(1))
        \ && (0 == <SID>IsWindowSpecial(2))
        \ && (0 != <SID>IsWindowSpecial(3)) )
      let l:winnr_lhs = 1
      let l:winnr_rhs = 2
    endif
  else
    " The project window is showing, so the user's window(s) are the second and
    " maybe the third window(s)
    if ( (0 == <SID>IsWindowSpecial(2))
        \ && (0 == <SID>IsWindowSpecial(3))
        \ && (0 != <SID>IsWindowSpecial(4)) )
      let l:winnr_lhs = 2
      let l:winnr_rhs = 3
    endif
  endif

  call s:ToggleProjectPost_ResizeTwoWindowView(l:winnr_lhs, l:winnr_rhs, l:cols_avail)

  " Move cursor back to window it was just in
  execute save_winnr . 'wincmd w'

  " NOTE: Use silent to avoid 'E35: No file name' warning message.
  silent! loadview
endfunction

" ***

" If the user is editing using two windows, resize and reposition the windows
" to the pleasurement of all
function s:ToggleProjectPost_ResizeTwoWindowView(winnr_lhs, winnr_rhs, cols_avail) abort
  if a:winnr_lhs == 0 || a:winnr_rhs == 0

    return
  endif

  " Switch to the second window, remember its buffer, and close the window
  execute a:winnr_rhs . 'wincmd w'
  let l:bufnr = winbufnr('%')
  close

  " Switch back to the first window and split it
  execute a:winnr_lhs . 'wincmd w'

  " Split the window either vertically or horizontally, depending on the
  " amount of room available and if the project window is showing.
  " NOTE We closed a window and use to (v)split to make a new window,
  "      which automatically sizes each window similarly. If we didn't
  "      close the window and instead wanted to resize each window
  "      manually, we'd call
  "         let half_width = &columns / 2
  "         execute 'vertical resize ' . half_width
  " Hack alert! a:winnr_lhs is 1 if project window isn't showing, 2 otherwise
  if a:winnr_lhs == 1 || a:cols_avail > 160
    " Split vertically
    execute 'vsplit'
  else
    " Split horizontally
    execute 'split'
  endif

  " Switch back to the (newly-created) second window and load the
  " remembered buffer
  execute a:winnr_rhs . 'wincmd w'
  execute 'buffer ' . l:bufnr
endfunction

" ***

" Test if a window is the Help, Quickfix, MiniBufExplorer, or Project window
" - CXREF/2025-02-02: See similar fcn. in author's other plugins:
"     g:embrace#windows#IsNormalBuffer
"   ~/.kit/nvim/embrace-vim/start/vim-buffer-delights/autoload/embrace/windows.vim
function! s:IsWindowSpecial(winnr)
  let l:is_special = 0

  if (-1 == winbufnr(a:winnr))
    let l:is_special = -1
  else
    let l:bufnr = winbufnr(a:winnr)

    let l:ftype = getbufvar(l:bufnr, "&filetype")

    if 0
      \ || -1 == l:bufnr
      \ || getbufvar(l:bufnr, '&buftype') != ''
      \ || getbufvar(l:bufnr, "&previewwindow")
      \ || !getbufvar(l:bufnr, "&modifiable")
      \ || !buflisted(l:bufnr)
      \ || l:ftype == 'qf'
      \ || l:ftype == 'git'
      \ || l:ftype == 'fugitiveblame'
      \ || bufname(l:bufnr) == '-MiniBufExplorer-'
      \ || (exists('g:proj_running')
      \     && a:winnr == bufwinnr(g:proj_running))

      let l:is_special = 1
    endif
  endif

  return l:is_special
endfunction

