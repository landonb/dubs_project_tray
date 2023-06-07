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
"   - To prevent project from splitting filenames on special characters,
"     like parentheses, and exclamation marks, include them here.

" 2018-08-09: Up until now, I've used:
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,}
"   - Today I've added parentheses, the bang, and the single quote.
" 2023-06-06: I've removed the single quote, which was also done wrong:
"     set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\'  <-- WRONG
"   - Including the literal quote character cause problems with plugins
"     that modify isfname, which usually entails caching the existing
"     value, setting a new value, and then restoring the old value.
"     But depending on how the plugin evaluates isfname, you'll likely
"     get an error, e.g., if you add a literal single quote ('), then
"     ftplugin/perl.vim (among others) fails, complaining:
"       E115: Missing single quote: '@,48-57,...
"   - The proper approach is to use ASCII codes in place of quotes,
"     e.g., avoid this:
"       set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,\'
"     and do this instead:
"       set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,39
""    - Here are a few ASCII codes: 39('), 34("), 48-57 (0-9).
"   - Nonetheless, I find it more likely that a path in docs or code
"     is surrounded by quotes, rather than contains quotes, in which
"     case `gf` and other commands that identify paths won't work
"     if the path is enclosed in quotes.
"     - As such, no longer including any quote characters in isfname.
"
" 2023-06-06: Note that `set` vs. `setlocal` doesn't matter, because
"   `isfname` is a global. (So if you run `setlocal isfname=@,48-57`
"   in one buffer, switch to another buffer, and then `echo &isfname`,
"   what you set in the other buffer is what you'll see).
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!

