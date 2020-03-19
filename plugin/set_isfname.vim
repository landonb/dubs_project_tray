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
"  silent! unlet g:loaded_dubs_set_isfname

if exists("g:loaded_dubs_set_isfname") || &cp
  finish
endif
let g:loaded_dubs_set_isfname = 1

" ***

" -------------------------------------------------------------------------
" isfname setting
" -------------------------------------------------------------------------

" 'isfname' string	(default for MS-DOS, Win32 and OS/2:
" 			     "@,48-57,/,\,.,-,_,+,,,#,$,%,{,},[,],:,@-@,!,~,="
" 			    for AMIGA: "@,48-57,/,.,-,_,+,,,$,:"
" 			    for VMS: "@,48-57,/,.,-,_,+,,,#,$,%,<,>,[,],:,;,~"
" 			    for OS/390: "@,240-249,/,.,-,_,+,,,#,$,%,~,="
" 			    otherwise: "@,48-57,/,.,-,_,+,,,#,$,%,~,=")
"
" Linux is the "otherwise" default, to which we'll add leafy brackets.
"
" 2018-08-09: See comments in plugin/dubs_project.vim's substitute(fnames, ...)
"   which uses the regex character class for file characters, ``\f``.
"   To prevent project from splitting filenames on special characters,
"   like parentheses, and exclamation marks, include them here.

" 2018-08-09: Up until now:
"   set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,}
" 2018-08-09: Adds parentheses, and bang. And single quote... and double quote.
"   (Also, is the triple comma, `,,,`, so that files with commas in their
"   names are recognized properly?)
" 2018-08-09: On second thought, including double quote messes up loading
"   .trustme.vim from within a project with a plus sign `+` in the path.
"   This I cannot explain.
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\',\"
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\'

