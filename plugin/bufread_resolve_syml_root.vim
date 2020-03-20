" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Project Page: https://github.com/landonb/dubs_project_tray
" License: GPLv3
" -------------------------------------------------------------------
" Copyright © 2009, 2015-2017 Landon Bouma.
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

" ***

" YOU: Uncomment the 'unlet', then <F9> to reload this file.
"       https://github.com/landonb/vim-source-reloader
"  silent! unlet g:loaded_dubs_resolve_syml_root

if exists("g:loaded_dubs_resolve_syml_root") || &cp
  finish
endif
let g:loaded_dubs_resolve_syml_root = 1

" ***


" ***

" Command to close opened file if opened at symlink path, and reopen at real path.
"
" - I've seen more basic, but broken, examples of how to do this, e.g.,
"       command! FollowSymlink execute "file " . resolve(expand("%")) | edit
"   but this approach has a glaring problem: if does not delete and wipe
"   the symlink buffer, so Vim thinks it has two buffers open to the same
"   file. So if you try to save the file opened second, it'll fail, and Vim
"   will gripe:
"       E13: File exists (add ! to override)
" - So open a new buffer, delete (technically, Wipe!) the old buffer (i.e.,
"   call `bw`, not `bd` -- if you :bd the symlink and open the canonical path,
"   Vim will open the symlink path, so weird!), and then call edit with the
"   canonical path.
"   - Ref: Trying to buffer-delete (:bd) a symlink vs. buf-wiping (:bw) it:
"     https://superuser.com/questions/960773/vim-opens-symlink-even-when-given-target-path-directly

function! FollowSymlinkAndCleanupBufSurfHistory()
  " Remove *previous* buffer, which is the (unlisted) netrw buffer (which
  " somehow slips into the BufSurf list, even though I tried to protect
  " against it -- but the appBufSurfAppendend does not fire for netrw?).
  " - Note that we remove w:history_index and not the last element.
  " MAYBE/2020-03-19: Filter every w:history element using buflisted, not just the 1.
"  if !exists("w:history") | return | endif
  let l:previdx = w:history_index - 1
  if !buflisted(w:history[l:previdx])
" I fixed this I THINK
echom "ERROR: UNEXPECTED"
echom "ERROR: UNEXPECTED"
    call remove(w:history, l:previdx)
    let w:history_index -= 1
  endif

  " Using '%:p' for full path, as opposed to possibly relative '%' path.
  let l:sympath = expand('%:p')
  " Check if file type is a symlink, and resolve to canonical path if so.
  if getftype(l:sympath) == 'link'
    " Resolve the file path and open the "actual" file.
    let l:canpath = resolve(l:sympath)


    if l:sympath != l:canpath
        if exists("w:history")
            let l:bufnr = winbufnr(winnr())
            " Remove the buffer to the symlink.
            call RemoveHistory
            call remove(w:history, w:history_index)
            let w:history_index -= 1

            enew

            " Remove the new buffer from vim-bursurf queue.
            call remove(w:history, w:history_index)
            let w:history_index -= 1
        endif

        " Note: Wipe the buffer, not delete, lest Vim re-open file at symlink path!
        " - WRONG: exe "bd " . l:sympath
        exe "bw " . l:sympath
        exe "edit " . l:canpath
    endif


  endif
endfunction







" ***

"

" ***
" *******
" ***

" Bugfix: Open canonical path and close symlinked path.
" - I experience problems with the mate-panel window list when window titles
"   contain certain emoji characters -- the window list changes from two rows
"   to one row!
"   - So as a workaround, I generally name the actual files with ASCII characters,
"     and then if I want to use emoji, I create a symlinks (I do this with notes
"     files, so that my project tray shows friendlier names, and do not do this
"     with code files; so really this workaround is for me and my notes symlinks).
"   - But when I open symlinks via netrw (but not via project.vim tray, because I
"     already fixed that to resolve symlinks), the symlinked file is opened -- and
"     if said file has any of those pesky emoji characters in it, the mate-panel
"     window list single-row issue gets tickled.
"   - So upon opening such files, resolve the symlink to the canonical path.
"   - Inspired by autocmd suggestion from reddit
"       https://www.reddit.com/r/vim/comments/97a34g/how_do_i_open_the_actual_file_in_vim_instead_of/
"     - But with tweaks:
"       - We need to buf-wipe the symlink-named buffer, which means we have to
"         open a new buffer, wipe the old, then open the buffer again but using
"         the actual file path.
"       - Also, blog post suggests hooking BufReadPost, but that did not work
"         (see comments above: trying `au BufRead[Post]` vs. setting g:Netrw_funcref,
"          with the autocmds, the symlink path is resolved, but buffer opens without
"          &filetype set!).
"     - See also original article apparently I found in 2017
"         http://inlehmansterms.net/2014/09/04/sane-vim-working-directories/
"       and the TBD_FollowSymlink_BROKE, above, indicated I had previously
"       tried to solve this problem but failed/gave up! But now, today, success!!

" Add function to netrw post-edit callback list (which could be undef or atom).
if !exists("g:Netrw_funcref")
  let g:Netrw_funcref = []
elseif type(g:Netrw_funcref) != v:t_list
  let g:Netrw_funcref = [g:Netrw_funcref]
endif
let g:Netrw_funcref += [function("FollowSymlinkAndCleanupBufSurfHistory")]

