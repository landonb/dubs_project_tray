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
"  silent! unlet g:loaded_dubs_netrw_wrap

if exists("g:loaded_dubs_netrw_wrap") || &cp
  finish
endif
let g:loaded_dubs_netrw_wrap = 1

" ***

" -------------------------------------------------------------------------
" netrw/vim-vinegar tweaking
" -------------------------------------------------------------------------

" 2017-11-02: % of current win to use for new win on 'o', 'v', and H/Vexplore.
" https://shapeshed.com/vim-netrw/
" https://github.com/tpope/vim-vinegar
let g:netrw_winsize = 33

" 1 - open files in a new horizontal split
" 2 - open files in a new vertical split
" 3 - open files in a new tab
" 4 - open in previous window
" 0 - re-use same window (default)
let g:netrw_browse_split = 0

" Press 'I' to toggle the banner.
let g:netrw_banner = 0

" There are four different view types: thin, long, wide and tree.
" Press 'i' to toggle the view.
" 2020-03-19: Ha! I've only recently started using a split explorer,
" and immediately ran into big problem: netrw does not resolve symlink
" path correctly -- symlinks to files not in the same directory as the
" symlink had incorrect paths. But seems to be tree-view specific!
" - AVOID: let g:netrw_liststyle = 3
"   Follow: "Netrw fails to open symlinks in tree mode #2386"
"   Opened 2017-11-28 (not by me!) and still open 2020-03-19.
"     https://github.com/vim/vim/issues/2386
" - Set the netrw lifestyle, er, liststyle to 'thin' or 'long' listings.
"   Opts- 'thin', one-file-per-line (0); long (1); wide (2); and tree (3).
"   - I tried long, but the tabstops do not align, so the details column,
"     well, it's not a column. Everything looks messy.
"   AVOID: let g:netrw_liststyle = 1
let g:netrw_liststyle = 0

" ***

