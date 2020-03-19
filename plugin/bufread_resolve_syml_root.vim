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

" YOU: Uncomment and <F9> to source/reload.
"  silent! unlet g:loaded_dubs_resolve_syml_root

if exists("g:loaded_dubs_resolve_syml_root") || &cp
  finish
endif
let g:loaded_dubs_resolve_syml_root = 1

" ***

" -------------------------------------------------------------------------
" Maintain working directory
" -------------------------------------------------------------------------
" 2017-12-12: A .trustme.sh script is writing its log to the wrong file
" because of what Vim considers the current working directory. I should
" probably fix this in the Bash script, but I can also keep Vim's `cwd`
" up to date with the window's buffer's file's project directory.
"
" Thanks to:
"
"   http://inlehmansterms.net/2014/09/04/sane-vim-working-directories/

" Follow symlinked file.
function! TBD_FollowSymlink_BROKE()
  let l:current_file = expand('%:p')
  " Check if file type is a symlink.
  if getftype(l:current_file) == 'link'
    " Resolve the file path and open the "actual" file.
    let l:actual_file = resolve(l:current_file)
    if l:current_file != l:actual_file
      " 2017-12-20: What the what?!! For the past week (since I
      " added this code 2017-12-12), some files (especially
      " .vimprojects) throw errors when I try to blandly save, e.g.,
      "     E13: File exists (use ! to override)
      " which I tracked down to calling :file -- and it happens
      " whether I `execute` or call it directly. And even more
      " bizarrely, it happens even though this block of code does
      " not execute! And even more mind blowingly confusingly, it
      " does not happen if I if-0 the block of code! So we'll just,
      " well, leave this code here as a testament to how much I love
      " Vim but also how quirky it can be sometimes. (Actually, not
      " too quirky; I cannot think of another Vim'ism like this.)
      " Note, too, if you :file the same path in a buffer, it barks:
      "     E95: Buffer with this name already exists
      " See also: `:h :file` (not `:h file`) or `:h CTRL-G`.
      if 0
        silent! execute 'file ' . l:actual_file
        "execute 'file ' . l:actual_file
        "file l:actual_file
      endif
    endif
  endif
endfunction

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
  " Using '%:p' for full path, as opposed to possibly relative '%' path.
  let l:sympath = expand('%:p')
  " Remove *previous* buffer, which is the (unlisted) netrw buffer (which
  " somehow slips into the BufSurf list, even though I tried to protect
  " against it -- but the appBufSurfAppendend does not fire for netrw?).
  " - Note that we remove w:history_index and not the last element.
  " MAYBE/2020-03-19: Filter every w:history element using buflisted, not just the 1.
  let l:histxbuf = w:history[w:history_index - 1]
  if !buflisted(l:histxbuf)
    call remove(w:history, w:history_index - 1)
    let w:history_index -= 1
  endif
  " Check if file type is a symlink, and resolve to canonical path if so.
  if getftype(l:sympath) == 'link'
    " Resolve the file path and open the "actual" file.
    let l:canpath = resolve(l:sympath)
    if l:sympath != l:canpath
        let l:bufnr = winbufnr(winnr())
        " Remove the buffer to the symlink.
        call remove(w:history, w:history_index)
        let w:history_index -= 1
        enew
        " Remove the new buffer from vim-bursurf queue.
        call remove(w:history, w:history_index)
        let w:history_index -= 1
        " Note: Wipe the buffer, not delete, lest Vim re-open file at symlink path!
        " - WRONG: exe "bd " . l:sympath
        exe "bw " . l:sympath
        exe "edit " . l:canpath
    endif
  endif
endfunction

" ***

" Set working directory to git project root, or
" to directory of current file if not git project.
function! SetProjectRoot()
  " Check for special paths, e.g., vim-fugitive paths look like:
  "   fugitive:///repo/path/.git//SHA1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/some/file
  if (expand('%:p') == '') || !empty(matchstr(expand('%:p'), '^fugitive://.*'))
    " E.g., this happens on opening Glog entry from quickfix.
    return
  endif
  " Default to the current file's directory.
  lcd %:p:h
  let l:git_dir = system("git rev-parse --show-toplevel")
  " See if the command output starts with 'fatal'
  " (if it does, it's not in a git repo, duh).
  " If git project, change local directory to git project root.
  if (l:git_dir != '') && empty(matchstr(l:git_dir, '^fatal:.*'))
    lcd `=l:git_dir`
  endif
endfunction

" ***
" *******
" ***

" Follow symlink and set working directory.
" 2017-12-20: See note in FollowSymlink, which is effectively disabled now.
" 2020-03-19: Last comments refers to now-named TBD_FollowSymlink_BROKE.
" - I sorta fixed FollowSymlinks to do a buffer dance, to wipe the buffer
"   opened at the symlink path. But I still have issues with applying to
"   to a BufRead, e.g., this does not work:
if 0
  " 2020-03-19: I also tried `au BufReadPost *` will same outcome:
  " notes (reST) file is opened, but (at least) &filetype not (or un)set.
  "   autocmd BufReadPost *
  "     \ ...
  autocmd BufRead *
    \ call FollowSymlink() |
    \ call SetProjectRoot()
endif
" - For whatever reason, that opens my rst files but clears &filetype!
"   Or prevents filetype from being set in first place, not really sure.
"   - Which means this fails similarly:
"       autocmd BufRead *.rst call FollowSymlink()

" We can at least take care of project root business!

autocmd BufRead * call SetProjectRoot()

" And we can also resolve symlinks from netrw, which is actually
" my only pain point -- I previously hacked (featured) project.vim
" to resolve symlinks on open.
" - So my 2 open-file vectors from within Vim, project.vim and netrw,
"   are patched and will figure out how to open each file at its
"   canonical path.
"   - However, you can still open the file at its symlink by calling
"     :e directly (which I rarely do), or by opening the file from the
"     command line (which is something I'll just have to be aware of
"     from within the terminal, whatever, no biggie).

" ***

" 2020-03-19: More code from a few years back newly disabled,
"             but keeping for posterity (or in lieu of having
"             a bug tracker for this issue, I'll just maintain
"             a file with a bottomload of comments to describe
"             it).
"
" netrw: follow symlink and set working directory
" NOTE: This is not perfect. See blog post.
"         http://inlehmansterms.net/2014/09/04/sane-vim-working-directories/
"       Apparently netrw *only* emits the CursorMoved command.
"       To see which autocommands get called, try:
"         :set verbose=9
"       And later reset it:
"         :set verbose=0
" 2020-03-19: Not sure if I just didn't read the netrw help years ago, but
" rather than hacking CursorMoved, we can hook Netrw_funcref. See below.
if 0
  autocmd CursorMoved silent *
    " short circuit for non-netrw files
    \ if &filetype == 'netrw' |
    \   call FollowSymlink() |
    \   call SetProjectRoot() |
    \ endif
endif

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

let g:Netrw_funcref = function("FollowSymlinkAndCleanupBufSurfHistory")

