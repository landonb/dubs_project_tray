" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_project_tray#🗂
" License: GPLv3 | Copyright © 2009, 2015-2017 Landon Bouma.
" Summary: Enhanced Project Plugin

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
" - Default is 'imstb' for Linux ('b' excluded for macOS|Windows).
if !exists('g:proj_flags')
  let g:proj_flags='imst'
endif

" ***

" FTREQ: Here are elsewhere, use g:vars to control bindings.
" - Another option is to skip a binding if already bound, e.g.,
"   if !hasmapto('<Plug>DubsProjectTray_ToggleProject_Wrapper')

" SYNC_ME: Dubs Vim's <M-????> mappings are spread across plugins. [M-S-4]
function! s:mappings_toggle_project_wrapper() abort
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

call s:mappings_toggle_project_wrapper()

" ***

" After Project() is used to setup the project buffer, we must use
" ToggleProject thereafter, unless the project buffer is :bwipeout.
" - Project() complains when called again and project buffer exists.
" - REFER: g:proj_running

let s:vimprojs_fname = '.vimprojects'
let s:projs_template = '.vimprojects.template'

function! s:ToggleProject_Wrapper() abort
  " Use mkview/loadview to store current view, i.e., to maintain
  " current folds (otherwise Vim resets them when you reenter buffer).
  " NOTE: Use silent to avoid 'E35: No file name' warning message.
  silent! mkview

  let l:save_winnr = winnr()

  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " the Project adds itself as the first window, so
    " we need to increase winnr by 1 to find our current
    " window again
    let l:save_winnr = l:save_winnr + 1
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
      call s:ToggleProject_Unitialized()
    endif
  else
    " Otherwise, we're losing the first window, so
    " compensate for the loss by subtracting one
    let l:save_winnr = l:save_winnr - 1
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
  let [l:winnr_lhs, l:winnr_rhs] = s:ToggleProjectPost_ProbeTwoWindowView()

  call s:ToggleProjectPost_ResizeTwoWindowView(l:winnr_lhs, l:winnr_rhs, l:cols_avail)

  " Move cursor back to window it was just in
  execute l:save_winnr . 'wincmd w'

  " NOTE: Use silent to avoid 'E35: No file name' warning message.
  silent! loadview
endfunction

" ***

function! s:ToggleProject_Unitialized() abort
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
      let l:projf = s:FindUsersVimProjects()
    endif

    if l:projf != ''
      " Weird: If we call the fcn. directly, e.g., `Project(l:projf)`
      "        then the Project function's variable is assigned the value
      "        l:projf (the *name* of the variable we're passing!). So
      "        we have to convert to a string first and use execute.
      execute 'Project ' . l:projf
    else
      call confirm('dubs: Cannot find ' . s:vimprojs_fname . ' file.', 'OK')
    endif
  endif
endfunction

" ***

" Checks if user is working on two buffers in two of the first three windows.
" Hint: the way dubs_project_tray sets it up, the Project window (file browser)
" is on the left, and the buffer explorer and quickfix window are on the bottom.
" That leaves one or two windows that the user is editing in the upper-right.
" If there are two windows, they're either side-by-side or stacked depending
" on how much room is available.
function! s:ToggleProjectPost_ProbeTwoWindowView() abort
  let l:winnr_lhs = 0
  let l:winnr_rhs = 0

  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " The project window is not showing, so the user's windows are the first
    " and maybe the second window (since Vim numbers windows 1, 2, 3, ..., from
    " left to right and top to bottom
    if ( (0 == s:IsWindowSpecial(1))
        \ && (0 == s:IsWindowSpecial(2))
        \ && (0 != s:IsWindowSpecial(3)) )

      let l:winnr_lhs = 1
      let l:winnr_rhs = 2
    endif
  else
    " The project window is showing, so the user's window(s) are the second and
    " maybe the third window(s)
    if ( (0 == s:IsWindowSpecial(2))
        \ && (0 == s:IsWindowSpecial(3))
        \ && (0 != s:IsWindowSpecial(4)) )

      let l:winnr_lhs = 2
      let l:winnr_rhs = 3
    endif
  endif

  return [l:winnr_lhs, l:winnr_rhs]
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

function! s:FindUsersVimProjects() abort
  " Look for user's projects file.
  let l:files = s:FindFile(s:vimprojs_fname)

  " Tell the user if they've got multiple project files.
  call s:AlertIfMultipleUsersVimProjectsFiles(l:files, 'file')

  if !empty(l:files)
    let l:user_projs = l:files[0]
  else
    " No file, but there should be a template we can copy.
    let l:tmplate = ''

    let l:files = s:FindFile(s:projs_template)
    call s:AlertIfMultipleUsersVimProjectsFiles(l:files, 'template')

    if !empty(l:files)
      let l:tmplate = l:files[0]
    endif

    let l:user_projs = s:DeployUsersVimProjectsTemplate(l:tmplate)
  endif

  return l:user_projs
endfunction

" COPYD/2025-02-02: FindFile et al shared between two plugins:
"   ~/.kit/nvim/landonb/start/dubs_grep_steady/plugin/dubs_grep_steady.vim
"   ~/.kit/nvim/landonb/start/dubs_project_tray/plugin/dubs_project_tray.vim

function! s:FindFile(fname) abort
  if a:fname == ''

    return []
  endif

  if has('nvim')
    let l:files = s:FindFileAnywhereOnRuntimepath_Nvim(a:fname)
  elseif v:version < 900
    " expand('<script>') is empty
    let l:files = s:FindFileAnywhereOnRuntimepath_Vim(a:fname)
  else
    " FTREQ: Or better yet: Add ~/.config path option.
    let l:files = s:FindFileInProjectOrRuntimeRoot_Vim(a:fname)
  endif

  return l:files
endfunction

function! s:FindFileAnywhereOnRuntimepath_Nvim(fname) abort
  let l:all = 1

  let l:files = nvim_get_runtime_file(a:fname, l:all)

  return l:files
endfunction

" SAVVY: Assumes split(&rtp)[0] is ~/.vim, which is generally the case.
" - ASIDE: In Neovim, root path on &rtp is ~/.config/nvim.
function! s:FindFileInProjectOrRuntimeRoot_Vim(fname) abort
  if pathogen#split(&rtp)[0] == ''
    " Unreachable path.

    return ''
  endif

  let l:fpath = findfile(a:fname, pathogen#split(&rtp)[0] . '/**')

  if l:fpath == ''
    " <script> is: /path/to/dubs_project_tray/plugin/dubs_project_tray.vim
    " del 2 heads: /path/to/dubs_project_tray/
    let l:proj_root = expand('<script>:h:h')

    if l:proj_root != ''
      let l:fpath = findfile(a:fname, l:proj_root . '/**')
    endif
  endif

  let l:user_projs = []

  if l:fpath != ''
    " Turn into a full path. See :h filename-modifiers
    let l:user_projs = [fnamemodify(l:fpath, ':p')]
  endif

  return l:user_projs
endfunction

" SAVVY: Alternative to previous fcn, though may take longer.
" - 2025-02-02: Notes from years ago suggest checking every
"   directory takes a while (think someone with 100 plugins
"   and no dubs_projects.vim file therein), but when tested
"   just now, it ran fine (though only checked ~10 paths).
function! s:FindFileAnywhereOnRuntimepath_Vim(fname) abort
  let l:fpath = ""

  for l:rtp_dir in pathogen#split(&rtp)
    let l:try_file = l:rtp_dir . '/' . a:fname

    if filereadable(l:try_file)
      let l:fpath = l:try_file

      break
    endif
  endfor

  let l:user_projs = []

  if l:fpath != ''
    " Turn into a full path. See :h filename-modifiers
    let l:user_projs = [fnamemodify(l:fpath, ':p')]
  endif

  return l:user_projs
endfunction

function! s:AlertIfMultipleUsersVimProjectsFiles(matches, what) abort
  if len(a:matches) <= 1

    return
  endif
  
  echom 'ALERT: dubs_project_tray: Found more than one user projects ' .. a:what .. ':'
  for l:path in a:matches
    echom '  ' .. l:path
  endfor
endfunction

" On first boot, make the project template.
" - E.g.,
"     command cp \
"       ~/.kit/nvim/landonb/start/dubs_project_tray/.vimprojects.template \
"       ~/.kit/nvim/landonb/start/dubs_project_tray/.vimprojects
"
" FIXME: Advise user to move to new file to private location
"        and to create a symlink in its new location (either
"        via UX message, or in the readme).

function! s:DeployUsersVimProjectsTemplate(tmplate) abort
  let l:user_projs = ''

  if a:tmplate != ''
    " Get the full path (:p), and drop the '.template'
    " extension, aka get the filename root (:r).
    let l:user_projs = fnamemodify(a:tmplate, ':p:r')

    if getftype(l:user_projs) != ''
      echom 'ALERT: dubs_project_tray: Cannot expand project file template: Target exists (broken symlink?): ' . l:user_projs

      let l:user_projs = ''
    else
      " Make a copy of the template.
      execute '!command cp ' . a:tmplate . ' ' . l:user_projs

      echom 'dubs_project_tray: Created new project file from template: ' . l:user_projs
    endif
  else
    " This is more of a GAFFE, i.e., more likely it's our error than users's.
    " - I.e., if this script is running, the project root should be on &rtp,
    "   and the template should be within the project directory (and we should
    "   have found it).
    echom 'ALERT: dubs_project_tray: Could not find project file template: ' .. s:projs_template
  endif

  return l:user_projs
endfunction

" ***

" Test if a window is the Help, Quickfix, MiniBufExplorer, or Project window
" - CXREF/2025-02-02: See similar fcn. in author's other plugins:
"     g:embrace#windows#IsNormalBuffer
"   ~/.kit/nvim/embrace-vim/start/vim-buffer-delights/autoload/embrace/windows.vim
function! s:IsWindowSpecial(winnr) abort
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

