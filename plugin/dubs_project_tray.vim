" File: dubs_project_tray.vim
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Last Modified: 2016.11.29
" Project Page: https://github.com/landonb/dubs_project_tray
" Summary: Enhanced Project Plugin
" License: GPLv3
" -------------------------------------------------------------------
" Copyright © 2009, 2015-2016 Landon Bouma.
" 
" This program is free software: you can redistribute it and/or
" modify it under the terms of the GNU General Public License as
" published by the Free Software Foundation, either version 3 of
" the License, or (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program. If not, see <http://www.gnu.org/licenses/>
" or write Free Software Foundation, Inc., 51 Franklin Street,
"                     Fifth Floor, Boston, MA 02110-1301, USA.
" ===================================================================

" FIXME: On first boot, make the project template.
"        E.g., /bin/cp ~/.vim/bundle/dubs_project_tray/.vimprojects.template
"          to dubs_all/.vimprojects
"          (Note that you can't use dubs_project_tray/.vimprojects
"           because it's not .gitignored from there.)
" See example dubs_project.vim. Search for: finddir('cmdt_paths.template', ...)

" ------------------------------------------
" About/Usage:

" See :help dubs-project-tray.

if exists("g:plugin_dubs_project_tray") || &cp
  finish
endif
let g:plugin_dubs_project_tray = 1

" Alt-Shift-4 // Toggle Project Browser
" --------------------------------
" EditPlus doesn't necessarily have an 
" Alt-Shift-4 mapping, but it does have 
" a Project menu. This is similar. But 
" better. =)

"let g:proj_window_width=30 " Default project window width
"let g:proj_window_width=3 " Default project window width
let g:proj_window_width=33 " Default project window width
"let g:proj_window_width=36 " Default project window width
"let g:proj_window_width=39 " Default project window width

" Remove the 'b' project flag, which uses browse() when handling 
" the \C command. Problem is, I cannot select a directory (it 
" always open the directory), so just use a simple edit box instead.
let g:proj_flags='imst' " Default was 'imstb', but browse() in Fedora is wonky

" NOTE noremap does not work
" SYNC_ME: Dubsacks' <M-????> mappings are spread across plugins. [M-S-4]
nmap <silent> <M-$> <Plug>ToggleProject_Wrapper
imap <silent> <M-$> <C-O><Plug>ToggleProject_Wrapper
"cmap <silent> <M-$> <C-C><Plug>ToggleProject
"omap <silent> <M-$> <C-C><Plug>ToggleProject

" ToggleProject_Wrapper
" --------------------------------

" You can only setup Project once. If you call it again with
" a path -- even with the same path we just used -- it'll
" complain. So set the path once and then just use toggle.
let s:project_loaded = 0

map <silent> <unique> <script> 
  \ <Plug>ToggleProject_Wrapper 
  \ :call <SID>ToggleProject_Wrapper()<CR>
"   2. Thunk the <Plug>
function s:ToggleProject_Wrapper()
  let save_winnr = winnr()
  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " the Project adds itself as the first window, so 
    " we need to increase winnr by 1 to find our current 
    " window again
    let save_winnr = save_winnr + 1
    if s:project_loaded == 1
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
    elseif s:project_loaded == 0
      if filereadable($HOME . '/.vimprojects')
        " By default, Project opens ~/.vimprojects.
        execute "ToggleProject"
        let s:project_loaded = 1
      else
        " The project file is not at the default location.
        " See if we can't find one in the user's Vim directory,
        " which should be the first element of the runtimepath.
        " This happens if the user installs Dubsacks using Pathogen.

        " Soooooo slow:
        "   let l:projf = findfile('.vimprojects',
        "                          \ pathogen#split(&rtp)[0] . "/**")
        let l:projf = ''
        for vim_dir in pathogen#split(&rtp)
          let try_file = vim_dir . '/' . '.vimprojects'
          if filereadable(try_file)
            let l:projf = try_file
            break
          endif
        endfor

        if l:projf != ''
          " Weird: If we call the fcn. directly, e.g., `Project(l:projf)`
          "        then the Project functions variable is assigned the value
          "        l:projf (the *name* of the variable we're passing!). So
          "        we have to convert to a string first and use execute.
          execute "Project ".l:projf
          let s:project_loaded = 1
          " Tell the user if they've got multiple project files.

          " Hey slow poke:
          "   let l:fcnt2 = findfile('.vimprojects',
                                \ pathogen#split(&rtp)[0] . "/**", -1)
          let l:fcnt = 0
          for vim_dir in pathogen#split(&rtp)
            let try_file = vim_dir . '/' . '.vimprojects'
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
            "                \ . ' .vimprojects files.', 'OK')
            echomsg 'Found ' . l:fcnt . ' .vimprojects files.'
          endif
        else
          call confirm('dubs: Cannot find .vimprojects file.', 'OK')
          let s:project_loaded = -1
        endif
      endif
      let s:project_loaded = 1
    " else s:project_loaded == -1, so do nothing.
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
  let cols_avail = &columns
  if exists('g:proj_running') && bufwinnr(g:proj_running) == 1
    let cols_avail = cols_avail - g:proj_window_width
  endif
  "
  " Next, see if two buffers are open, and figure out which windows they're in.
  " Hint: the way dubsacks sets it up, the Project window (file browser) is on 
  " the left, and the buffer explorer and quickfix window are on the bottom.
  " That leaves one or two windows that the user is editing in the upper-right.
  " If there are two windows, they're either side-by-side or stacked depending
  " on how much room is available.
  let winnr_lhs = 0
  let winnr_rhs = 0
  if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
    " The project window is not showing, so the user's windows are the first
    " and maybe the second window (since Vim numbers windows 1, 2, 3, ..., from
    " left to right and top to bottom
    if ( (0 == <SID>IsWindowSpecial(1))
        \ && (0 == <SID>IsWindowSpecial(2))
        \ && (0 != <SID>IsWindowSpecial(3)) )
      let winnr_lhs = 1
      let winnr_rhs = 2
    endif
  else
    " The project window is showing, so the user's window(s) are the second and
    " maybe the third window(s)
    if ( (0 == <SID>IsWindowSpecial(2))
        \ && (0 == <SID>IsWindowSpecial(3))
        \ && (0 != <SID>IsWindowSpecial(4)) )
      let winnr_lhs = 2
      let winnr_rhs = 3
    endif
  endif
  "
  " If the user is editing using two windows, resize and reposition the windows
  " to the pleasurement of all
  if winnr_lhs != 0 && winnr_rhs != 0
    " Switch to the second window, remember its buffer, and close the window
    execute winnr_rhs . 'wincmd w'
    let bufnr = winbufnr("%")
    close
    " Switch back to the first window and split it
    execute winnr_lhs . 'wincmd w'
    " Split the window either vertically or horizontally, depending on the
    " amount of room available and if the project window is showing.
    " NOTE We closed a window and use to (v)split to make a new window, 
    "      which automatically sizes each window similarly. If we didn't 
    "      close the window and instead wanted to resize each window
    "      manually, we'd call
    "         let half_width = &columns / 2
    "         execute 'vertical resize ' . half_width
    " Hack alert! winnr_lhs is 1 if project window isn't showing, 2 otherwise
    if winnr_lhs == 1 || cols_avail > 160
      " Split vertically
      execute 'vsplit'
    else
      " Split horizontally
      execute 'split'
    endif
    " Switch back to the (newly-created) second window and load the
    " remembered buffer
    execute winnr_rhs . 'wincmd w'
    execute "buffer " . bufnr
  endif

  " Move cursor back to window it was just in
  execute save_winnr . 'wincmd w'

endfunction

" Test if a window is the Help, Quickfix, MiniBufExplorer, or Project window
function! s:IsWindowSpecial(window_nr)
  let is_special = 0
  if (-1 == winbufnr(a:window_nr))
    let is_special = -1
  else
    let buffer_nr = winbufnr(a:window_nr)
    if ( (-1 != buffer_nr)
        \ && ( (getbufvar(buffer_nr, "&buftype") == "help")
          \ || (getbufvar(buffer_nr, "&buftype") == "quickfix")
          \ || (bufname(buffer_nr) == "-MiniBufExplorer-")
          \ || ( (exists('g:proj_running')) 
              \ && (a:window_nr == bufwinnr(g:proj_running)) ) ) )
      " FIXME There's probably an easy way to check if a window/buffer is normal
      let is_special = 1
    endif
  endif
  return is_special
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Obsolete Code
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Alt-Shift-7 // Toggle File Browser
" --------------------------------
" NERDTree to the rescue.
" 2010.06.14: Disabled; I don't use NERDTree! 
"             I've been grooving on the Project plugin instead.
" 2015.01.14: And now I'm grooving on Command-T more so than Project;
"             see dubs_file_finder.
" (Note: It's M-&, not M-S-7)
"" SYNC_ME: Dubsacks' <M-????> mappings are spread across plugins. [M-S-7]
"noremap <M-&> :NERDTreeToggle<CR>
"inoremap <M-&> <C-O>:NERDTreeToggle<CR>
""cnoremap <M-&> <C-C>:NERDTreeToggle<CR>
""onoremap <M-&> <C-C>:NERDTreeToggle<CR>

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" cookiecutter support
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" I guess Vim doesn't think brackets{} are parts of file paths names.
"
" And we can't add {{cookiecutter.paths}} otherwise.

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" isfname setting
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" 'isfname' string	(default for MS-DOS, Win32 and OS/2:
" 			     "@,48-57,/,\,.,-,_,+,,,#,$,%,{,},[,],:,@-@,!,~,="
" 			    for AMIGA: "@,48-57,/,.,-,_,+,,,$,:"
" 			    for VMS: "@,48-57,/,.,-,_,+,,,#,$,%,<,>,[,],:,;,~"
" 			    for OS/390: "@,240-249,/,.,-,_,+,,,#,$,%,~,="
" 			    otherwise: "@,48-57,/,.,-,_,+,,,#,$,%,~,=")
"
" Linux is the "otherwise" default, to which we'll add leafy brackets.

set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,}

