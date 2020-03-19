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
function! FollowSymlink()
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
  end
endfunction

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

" Follow symlink and set working directory.
" 2017-12-20: See note in FollowSymlink, which is effectively disabled now.
autocmd BufRead *
  \ call FollowSymlink() |
  \ call SetProjectRoot()

" netrw: follow symlink and set working directory
" NOTE: This is not perfect. See blog post. Apparently
"         netrw *only* emits the CursorMoved command.
"       To see which autocommands get called, try:
"         :set verbose=9
"       And later reset it:
"         :set verbose=0
autocmd CursorMoved silent *
  " short circuit for non-netrw files
  \ if &filetype == 'netrw' |
  \   call FollowSymlink() |
  \   call SetProjectRoot() |
  \ endif

