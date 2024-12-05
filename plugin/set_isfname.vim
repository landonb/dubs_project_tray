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
"   which uses the regex character class for file characters, `\f`.
"   - To prevent the plugin project from splitting filenames on special
"     characters, like exclamation marks, include them here.
" - isfname is also used by `gf` command to identify the filename under
"   the cursor.

" 2018-08-09: Up until now, I've used:
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,}
" - Today I've added parentheses, the bang, and the single quote.
"     " set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,(,),!,\'
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,(,),!,39
"
" - At some point btw. 2018-08-09-2023-06-06, added braces:
"     " set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,39
"
" 2023-06-06: The single quote was being specified incorrectly:
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\'  <-- WRONG
" - Including the literal quote character cause problems with plugins
"   that modify isfname, which usually entails caching the existing
"   value, setting a new value, and then restoring the old value.
"   - But depending on how the plugin evaluates isfname, you'll likely
"     get an error, e.g., if you add a literal single quote ('), then
"     ftplugin/perl.vim (among others) fails, complaining:
"         E115: Missing single quote: '@,48-57,...
"   - The proper approach is to use ASCII codes in place of quotes,
"     e.g., avoid this:
"       set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\'
"     and do this instead:
"       set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,39
"
" - REFER: Here are relevant ASCII codes: 39('), 34("), 48-57 (0-9).
"
" 2023-06-06: Note that `set` vs. `setlocal` doesn't matter, because
"   `isfname` is a global. (So if you run `setlocal isfname=@,48-57`
"   in one buffer, switch to another buffer, and then `echo &isfname`,
"   what you set in the other buffer is what you'll see).
"
" 2023-10-03: Note that including the single quote has one drawback —
" the `gf` command won't work on single-quoted strings. But it will
" now work on filepaths that contain quotes! (So it's a compromise.)
" - E.g., you can open a file from Vim (e.g., using `gf`) on strings like:
"     /music/hits/sweet-child-o'-mine
"     \"/music/hits/sweet-child-o'-mine"
"   But you cannot open the same path if single-quoted paths, e.g.:
"     '/music/hits/sweet-child-o'-mine'  # `gf` won't work on this
"   Though you cannot have it both ways — You either allow single quotes
"   to be in path name, or you support single-quote path values, but you
"   cannot have both.
" - This comment re: isfname:
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,39
"
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,39

