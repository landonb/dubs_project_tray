" vim:tw=0:ts=4:sw=4:et:norl:
" File:        project.vim
" Maintainer+: Landon Bouma <https://tallybark.com/>
" Project URL: https://github.com/landonb/dubs_project#🗂
"  vim:foldmethod=marker:foldmarker=<<<,>>>:foldlevel=20
"  Fold hints: zM closes all, zR opens all; zm/zr close/open 1; za/zA toggle.
"=============================================================================
" Orig Author: Aric Blumer (Aric.Blumer at aricvim@charter.net)
" Auth Change: Fri 13 Oct 2006 09:47:08 AM EDT
" Version:     1.4.1
" See documentation in accompanying help file
" You may use this code in whatever way you see fit.
"=============================================================================
" 2014.01.21: See also: https://github.com/destroy/project.vim

" HINT: To reload this script, try:
"   :unlet g:plugin_dubs_project
"   <F9>
" EXCEPT: I'm not sure how to reload the project tray buffer,
"         which still uses the old code. So currently you
"         gotta restart Vim to reload this code. Somewhat
"         annoying, but this project (ha!) doesn't change
"         much.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:plugin_dubs_project
endif

if exists('g:plugin_dubs_project') || &cp

  finish
endif

let g:plugin_dubs_project = 1

" -------------------------------------------------------------------

let g:plugin_dubs_project_skip_symlink_dirs = 0

function! s:Project(filename) " <<<
    " Initialization <<<
    function! s:InitializeGlobals() abort
        if exists("g:proj_running") && bufnr(g:proj_running) == -1
            unlet! g:proj_running
        endif
        if !exists('g:proj_window_width')
            " Default project window width.
            " - This value already set (to 33) by the other plugin file
            "   when it was sourced (vs. here in :Project callback).
            "   ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project_tray.vim
            let g:proj_window_width = get(g:, 'proj_window_width', 33)
        endif
        if !exists('g:proj_window_increment')
            " Project Window width increment (used on <Space> to toggle wider width).
            let g:proj_window_increment = get(g:, 'proj_window_increment', 100)
        endif
        if !exists('g:proj_flags')
            " i: Print directory path progress messages on refresh.
            " m: Define <Plug>ProjectOnly
            " g: Add nmap <F12> <Plug>ToggleProject
            " s: Disable sort lines on refresh (use readdir order, then
            "    g:proj_sort filter, also g:proj_unique will sort).
            " t: Make <Space> to expand project window a toggle vs. just expanding.
            " b: Uses :browse dialog to obtain directory path for new project.
            "    Otherwise uses simple prompt.
            " c: When opening entry, hides Project window and resizes equally.
            " l: Use :lcd for CD= command, otherwise :cd.
            " v: Use :grep (otherwise uses :vimpgrep).
            " B: Call `botright copen` instead of `copen` to open quickfix using full
            "    horizontal width; and don't jump to first grep match.
            " F: Use "floating" window (*not* a Neovim floating window; this flag
            "    and doc. created before Neovim forked; it simply means to open the
            "    Project window in a new split from the current window)
            " L: When project uses CD=, sets up BufEnter, BufLeave, BufWipeout autocmd's
            "    to save/restore cwd.
            " S: Sort lines on refresh (see also 's' option and g:proj_sort).
            " T: Go to top of fold on project listing refresh.
            " n: Calls :setlocal number
            " See also g: vars:
            "   g:syntax_on
            if has("win32") || has("mac")
                " Project default flags for windows/mac
                let g:proj_flags='imst'
            else
                " Project default flags for everything else
                let g:proj_flags='imstb'
            endif
        endif
    endfunction
    function! s:ResolveVimprojectsPath(filename) abort
        if exists("g:proj_running")
            if strlen(a:filename) != 0
                call confirm('Project already loaded; ignoring filename "'
                \ .. a:filename .. "\".\n"
                \ .. 'See ":help project-invoking" for information about changing project files.',
                \ "&OK",
                \ 1)
            endif
            let l:filename = bufname(g:proj_running)
        else
            if strlen(a:filename) == 0
                " Default project filename
                " - FTREQ: This should be elsewhere, and not at top-level user home,
                "   perhaps under ~/.config/${NVIM_APPNAME}/
                let l:filename = get(g:, 'proj_filename', '~/.vimprojects')
            else
                let l:filename = a:filename
            endif
        endif
        return l:filename
    endfunction
    function! s:OpenOrFocusProjectWindow(filename) abort
        if !exists("g:proj_running") || (bufwinnr(g:proj_running) == -1) " Open the Project Window
            if match(g:proj_flags, '\CF') != -1
                " Open Project window in vertical split on right of current window.
                exec 'silent vertical new ' .. a:filename
            else
                " 
                exec 'silent vertical topleft ' .. g:proj_window_width .. 'split'
                exec 'edit ' .. a:filename
            endif
            " So the Project window stays the same width as user
            " resizes the app window. REFER: |equalalways|
            setlocal winfixwidth
            setlocal nomodeline
            " So that <Home>/<End> doesn't scroll horizontally (which happens
            " if a line is almost as long as the window width, and you <End>
            " or |$|, (Neo)vim scrolls horizontally to ensure cursor is
            " |sidescrolloff| columns from the edge of the window).
            " - This plays nice with LazyVim/other distros/or if user sets this globally.
            setlocal sidescrolloff=0
        else
            " Project running and visible, so just focus its window.
            " - If toggling off, caller will `hide` buffer (and window) next.
            exec 'silent! ' .. bufwinnr(g:proj_running) .. 'wincmd w'

            return 1
        endif

        return 0
    endfunction
    function! s:PrepareReusableCommands() abort
        " Process the flags
        let b:proj_cd_cmd='cd'
        if match(g:proj_flags, '\Cl') != -1
            let b:proj_cd_cmd = 'lcd'
        endif

        let b:proj_locate_command='silent! wincmd H'
        let b:proj_resize_command='exec ''vertical resize ''.g:proj_window_width'
        if match(g:proj_flags, '\CF') != -1
            " Set the resize commands to nothing
            let b:proj_locate_command=''
            let b:proj_resize_command=''
        endif

        let g:proj_last_buffer = -1
    endfunction
    ">>>
    " ProjFoldText() <<<
    "   The foldtext function for displaying just the description.
    function! ProjFoldText()
        let line=substitute(getline(v:foldstart),'^[ \t#]*\([^=]*\).*', '\1', '')
        " 2015.02.11: [lb] Here and throughout, I added [^{] and {$ to
        " ensure we're dealing with fold delimiters and not confusing that
        " delimiter with a value pathname (with on *nix can contain brackets).
        let line=strpart('                                     ', 0, (v:foldlevel - 1)).substitute(line,'\s*{[^{]\s*', '', '')
        return line
    endfunction ">>>
    " s:SetLocalOptions() <<<
    "   Ensure everything is set up
    function! s:SetLocalOptions()
        setlocal foldenable foldmethod=marker foldmarker={,} commentstring=%s foldcolumn=0 nonumber norelativenumber noswapfile shiftwidth=1 signcolumn=no
        setlocal foldtext=ProjFoldText() nobuflisted nowrap
        let l:minwidth = max([1, &winminwidth])
        exec "setlocal winwidth=" .. l:minwidth
        if match(g:proj_flags, '\Cn') != -1
            setlocal number
        endif
    endfunction ">>>
    " Syntax Stuff <<<
    function! s:CreateProjectSyntaxRulesAndHighlights() abort
        if match(g:proj_flags, '\Cs') == -1 || !has('syntax') || !exists('g:syntax_on')

            return
        endif

        syntax clear

        syntax match projectDescriptionDir '^\s*.\{-}=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
        syntax match projectDescription    '\<.\{-}='he=e-1,me=e-1         contained nextgroup=projectDirectory contains=projectWhiteError
        syntax match projectDescription    '{\|}'
        syntax match projectDirectory      '=\(\\ \|\f\|:\)\+'             contained
        syntax match projectDirectory      '=".\{-}"'                      contained
        syntax match projectScriptinout    '\<in\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
        syntax match projectScriptinout    '\<out\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
        syntax match projectComment        '#.*'
        syntax match projectCD             '\<CD\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
        " 2020-01-23: (lb): Note to self: .\{-} is Vim's non-greedy .*
        syntax match projectFilterEntry    '\<filter\s*=".\{-}"'           contains=projectWhiteError,projectFilterError,projectFilter,projectFilterRegexp
        syntax match projectFilter         '\<filter='he=e-1,me=e-1        contained nextgroup=projectFilterRegexp,projectFilterError,projectWhiteError
        syntax match projectExcludeEntry   '\<exclude\s*=".\{-}"'          contains=projectWhiteError,projectExcludeError,projectExclude,projectExcludeRegexp
        syntax match projectExclude        '\<exclude='he=e-1,me=e-1       contained nextgroup=projectExcludeRegexp,projectExcludeError,projectWhiteError
        syntax match projectFlagsEntry     '\<flags\s*=\( \|[^ ]*\)'       contains=projectFlags,projectWhiteError
        syntax match projectFlags          '\<flags'                       contained nextgroup=projectFlagsValues,projectWhiteError
        syntax match projectFlagsValues    '=[^ ]* 'hs=s+1,me=e-1          contained contains=projectFlagsError
        syntax match projectFlagsError     '[^rtTsSwl= ]\+'                contained
        syntax match projectWhiteError     '=\s\+'hs=s+1                   contained
        syntax match projectWhiteError     '\s\+='he=e-1                   contained
        syntax match projectFilterError    '=[^"]'hs=s+1                   contained
        syntax match projectFilterRegexp   '="[^"]\{-}"'hs=s+1             contained
        syntax match projectExcludeError   '=[^"]'hs=s+1                   contained
        syntax match projectExcludeRegexp  '="[^"]\{-}"'hs=s+1             contained
        syntax match projectFoldText       '^[^=]\+{'

        highlight def link projectDescription   Identifier
        highlight def link projectScriptinout   Identifier
        highlight def link projectFoldText      Identifier
        highlight def link projectComment       Comment
        highlight def link projectFilter        Identifier
        highlight def link projectExclude       Identifier
        highlight def link projectFlags         Identifier
        highlight def link projectDirectory     Constant
        highlight def link projectFilterRegexp  String
        highlight def link projectExcludeRegexp String
        highlight def link projectFlagsValues   String
        highlight def link projectWhiteError    Error
        highlight def link projectFlagsError    Error
        highlight def link projectFilterError   Error
        highlight def link projectExcludeError  Error
    endfunction ">>>
    " s:SortR(start, end) <<<
    " Sort lines.  SortR() is called recursively.
    "  from ":help eval-examples" by Robert Webb, slightly modified
    function! s:SortR(start, end)
        if (a:start >= a:end)
            return
        endif
        let partition = a:start - 1
        let middle = partition
        let partStr = getline((a:start + a:end) / 2)
        let i = a:start
        while (i <= a:end)
            let str = getline(i)
            if str < partStr
                let result = -1
            elseif str > partStr
                let result = 1
            else
                let result = 0
            endif
            if (result <= 0)
                let partition = partition + 1
                if (result == 0)
                    let middle = partition
                endif
                if (i != partition)
                    let str2 = getline(partition)
                    call setline(i, str2)
                    call setline(partition, str)
                endif
            endif
            let i = i + 1
        endwhile
        if (middle != partition)
            let str = getline(middle)
            let str2 = getline(partition)
            call setline(middle, str2)
            call setline(partition, str)
        endif
        call s:SortR(a:start, partition - 1)
        call s:SortR(partition + 1, a:end)
    endfunction ">>>
    " s:IsAbsolutePath(path) <<<
    "   Returns true if filename has an absolute path.
    function! s:IsAbsolutePath(path)
        if a:path =~ '^ftp:' || a:path =~ '^rcp:' || a:path =~ '^scp:' || a:path =~ '^http:'
            return 2
        endif
        if a:path =~ '\$'
            let path=expand(a:path) " Expand any environment variables that might be in the path
        else
            let path=a:path
        endif
        if path[0] == '/' || path[0] == '~' || path[0] == '\\' || path[1] == ':'
            return 1
        endif
        return 0
    endfunction ">>>
    " s:DoSetupAndSplit() <<<
    "   Call SetLocalOptions to ensure the settings are correct.
    "   Split to the next file.
    function! s:DoSetupAndSplit()
        call s:SetLocalOptions()                " Ensure that all the settings are right
        let l:proj_winnr = winnr()        " Determine if there is a CTRL_W-p window
        silent! wincmd p
        let l:split_nr = winnr()
        if !s:IsWindowSplittable(l:split_nr, l:proj_winnr)
            let l:winnr_lt = 0
            let l:winnr_gt = 0
            let l:offset_lt = 0
            let l:offset_gt = 0
            let l:final_winnr = winnr('$')
            for l:visit_winnr in range(1, l:final_winnr)
                if l:visit_winnr == l:split_nr
                    " Already checked.
                    continue
                endif
                if s:IsWindowSplittable(l:visit_winnr, l:proj_winnr)
                    if l:visit_winnr < l:split_nr
                        let l:winnr_lt = l:visit_winnr
                        let l:offset_lt = l:split_nr - l:visit_winnr
                    elseif l:winnr_gt == 0
                        let l:winnr_gt = l:visit_winnr
                        let l:offset_gt = l:visit_winnr - l:split_nr
                    endif
                endif
            endfor
            if l:offset_lt && l:offset_gt
                if l:offset_lt < l:offset_gt
                    let l:split_nr = l:winnr_lt
                else
                    let l:split_nr = l:winnr_gt
                endif
            elseif l:offset_lt
                let l:split_nr = l:winnr_lt
            elseif l:offset_gt
                let l:split_nr = l:winnr_gt
            endif
        endif
        if l:split_nr != proj_winnr
            " Found an available window to load into.
            silent! execute l:split_nr .. 'wincmd W'
        else
            " If l:split_nr == winnr(), then there is no CTRL_W-p window
            " So we have to create a new one
            if exists('g:proj_running') && (bufnr('%') == g:proj_running)
                exec 'silent vertical new'
            else
                exec 'silent vertical split | silent! bnext'
            endif
            " Go back to the Project Window and ensure it's the correct width.
            wincmd p
            exec b:proj_locate_command
            exec b:proj_resize_command
            wincmd p
        endif
    endfunction
    function! s:IsWindowSplittable(winnr, proj_winnr)
        return (getbufvar(winbufnr(a:winnr), "&buftype") == "")
            \ && (a:winnr != a:proj_winnr)
    endfunction ">>>
    " s:DoSetupAndSplit_au() <<<
    "   Same as above but ensure that the Project window is the current
    "   window.  Only called from an autocommand
    function! s:DoSetupAndSplit_au()
        if exists('g:proj_running') && (winbufnr(0) != g:proj_running)
            return
        endif
        call s:SetLocalOptions()        " Ensure that all the settings are right
        if winbufnr(2) == -1            " We're the only window right now.
            " If two windows are open, including the tray, and the other window
            " is closed, BufEnter actions this function, but the split fails,
            " indicating, 'Can't split a window while closing another'. We can
            " ignore the error with silent!, but then test if actually split.
            silent! exec 'silent vertical split | bnext'
            if winbufnr(2) == -1
                " Per previous comment, split failed if Vim is closing a window
                " (and I [lb] don't know how to detect that state easily, so
                "  this work-around instead).
                " Note that if we left the project tray as the only window, not
                " only does it look funny, but opening a file from the tray
                " replaces the tray with that file, in the same window (which
                " could be some other issue causing this; but don't care). So
                " not very useful. Instead, return now, which leaves the window
                " the user was closing as the only window (i.e., tray closes).
                return
            endif
            if exists("g:proj_running") && (bufnr('%') == g:proj_running)
                enew
            endif
            if bufnr('%') == g:proj_last_buffer | bnext | bprev | bnext | endif
            " Go back to the Project Window and ensure it's the correct width.
            wincmd p
            exec b:proj_locate_command
            exec b:proj_resize_command
        elseif(winnr() != 1)
            exec b:proj_locate_command
            exec b:proj_resize_command
        endif
    endfunction
    function! s:RecordPrevBuffer_au()
        let g:proj_last_buffer = bufnr('%')
    endfunction ">>>
    " s:get_correct_foldlevel(lineno) <<<
    " 2015.02.11: Added by [lb] to support {{cookiecutter}} directories
    "             and other paths with brackets in their name.
    function! s:get_correct_foldlevel(lineno)
        let foldlev = foldlevel(a:lineno)

        " Do substitute to count number of left brackets.
        " Note the 'n' actually skips the match, so no substitution
        " happens (we could instead .s/{/{/g but that adds an undo).

        " [lb] tried a try/catch/endtry here but I'd still get an
        " error message, and silent! seems to suppress both the
        " message and the error. Just be sure to clear v:statusmsg
        " first: if it's not and the substitute fails, it won't be
        " reset and will contain whatever its last value was, and then
        " we can't test it to see if the substitute was successful.
        let v:statusmsg = ""
        " Count the number of opening brackets, which are legal
        " directory characters but also used to delimit folds.
        " The Vim substitute operator returns, e.g., "5 matches on 1 line".
        " A few tests [2023-01-29: I \"-delimited the double-quotes to fix Vim highlighting...???]:
        "   s/{//gn | echo v:statusmsg \" { { { {
        "   s/{//gn | let l_bracket_cnt = split(v:statusmsg)[0] \" { { { {
        " Possible raises we'll ignore (no try/catch/endtry) b/c of silent!:
        "   E16: Invalid range
        "   E486: Pattern not found: {
        silent! exe a:lineno . "s/{//gn"
        let captured_sm = v:statusmsg
        if (captured_sm != "")
            let l_bracket_cnt = split(captured_sm)[0]
            if (l_bracket_cnt)
                let foldlev -= l_bracket_cnt - 1
            endif
        endif
        return foldlev
    endfunction ">>>
    " s:RecursivelyConstructDirectives(lineno) <<<
    "   Construct the inherited directives
    function! s:RecursivelyConstructDirectives(lineno)
        let lineno=s:FindFoldTop(a:lineno)
        let foldlineno = lineno
        let foldlev=s:get_correct_foldlevel(lineno)
        let parent_infoline = ''
        if foldlev > 1
            while s:get_correct_foldlevel(lineno) >= foldlev " Go to parent fold
                if lineno < 1
                    echoerr 'Some kind of fold error.  Check your syntax.'
                    return
                endif
                let lineno = lineno - 1
            endwhile
            let parent_infoline = s:RecursivelyConstructDirectives(lineno)
        endif
        let parent_home = s:GetHome(parent_infoline, '')
        let parent_c_d = s:GetCd(parent_infoline, parent_home)
        let parent_scriptin = s:GetScriptin(parent_infoline, parent_home)
        let parent_scriptout = s:GetScriptout(parent_infoline, parent_home)
        let parent_filter = s:GetFilter(parent_infoline, '*')
        let parent_exclude = s:GetExclude(parent_infoline, '')
        let infoline = getline(foldlineno)
        " Extract the home directory of this fold
        let home=s:GetHome(infoline, parent_home)
        if home != ''
            if (s:get_correct_foldlevel(foldlineno) == 1) && !s:IsAbsolutePath(home)
                call confirm('Outermost Project Fold must have absolute path!  Or perhaps the path does not exist.', "&OK", 1)
                let home = '~'  " Some 'reasonable' value
            endif
        endif
        " Extract any CD information
        let c_d = s:GetCd(infoline, home)
        if c_d != ''
            if (s:get_correct_foldlevel(foldlineno) == 1) && !s:IsAbsolutePath(c_d)
                call confirm('Outermost Project Fold must have absolute CD path!  Or perhaps the path does not exist.', "&OK", 1)
                let c_d = '.'  " Some 'reasonable' value
            endif
        else
            let c_d=parent_c_d
        endif
        " Extract scriptin
        let scriptin = s:GetScriptin(infoline, home)
        if scriptin == ''
            let scriptin = parent_scriptin
        endif
        " Extract scriptout
        let scriptout = s:GetScriptout(infoline, home)
        if scriptout == ''
            let scriptout = parent_scriptout
        endif
        " Extract filter
        let filter = s:GetFilter(infoline, parent_filter)
        let exclude = s:GetExclude(infoline, parent_exclude)
        if filter == '' | let filter = parent_filter | endif
        if exclude == '' | let exclude = parent_exclude | endif
        return s:ConstructInfo(home, c_d, scriptin, scriptout, '', filter, exclude)
    endfunction ">>>
    " s:ConstructInfo(home, c_d, scriptin, scriptout, flags, filter) <<<
    function! s:ConstructInfo(home, c_d, scriptin, scriptout, flags, filter, exclude)
        let retval='Directory='.a:home
        if a:c_d[0] != ''
            let retval=retval.' CD='.a:c_d
        endif
        if a:scriptin[0] != ''
            let retval=retval.' in='.a:scriptin
        endif
        if a:scriptout[0] != ''
            let retval=retval.' out='.a:scriptout
        endif
        if a:filter[0] != ''
            let retval=retval.' filter="'.a:filter.'"'
        endif
        if a:exclude[0] != ''
            let retval=retval.' exclude="'.a:exclude.'"'
        endif
        return retval
    endfunction ">>>
    " s:OpenEntry(line, precmd, editcmd) <<<
    "   Get the filename under the cursor, and open a window with it.
    function! s:OpenEntry(line, precmd, editcmd, dir)
        silent exec a:precmd
        if (a:editcmd[0] != '')
            if a:dir
                let fname='.'
            else
                if (s:get_correct_foldlevel(a:line) == 0) && (a:editcmd[0] != '')
                    " If we're outside a fold, do nothing
                    return 0
                endif
                " Get rid of comments and whitespace before comment
                let fname=substitute(getline(a:line), '\s*#.*', '', '')
                " Get rid of leading whitespace
                let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
                if strlen(fname) == 0
                    " The line is blank. Do nothing.
                    return 0
                endif
            endif
        else
            let fname='.'
        endif
        let infoline = s:RecursivelyConstructDirectives(a:line)
        let retval=s:OpenEntry2(a:line, infoline, fname, a:editcmd)
        call s:DisplayInfo()
        return retval
    endfunction ">>>
    " s:OpenEntry2(line, infoline, precmd, editcmd) <<<
    "   Get the filename under the cursor, and open a window with it.
    function! s:OpenEntry2(line, infoline, fname, editcmd)
        let fname=escape(a:fname, ' %#')        " Thanks to Thomas Link for cluing me in on % and #
        let home=s:GetHome(a:infoline, '').'/'
        if home=='/'
            echoerr 'Project structure error. Check your syntax.'
            return
        endif
        "Save the cd command
        let cd_cmd = b:proj_cd_cmd
        if a:editcmd[0] != '' " If editcmd is '', then just set up the environment in the Project Window
            call s:DoSetupAndSplit()
            " If it is an absolute path, don't prepend home
            if !s:IsAbsolutePath(fname)
                let fname=home.fname
            endif
            " 2020-03-18: (lb): If you open one file and then open another that's
            " a symlink to it, Vim pops up the dreaded (or just annoying) alert,
            " "Swap File <> Already Exists!". So resolve paths.
            let fname=resolve(expand(fname))
            if s:IsAbsolutePath(fname) == 2
                " Starts with '^ftp:'|'^rcp:'|'^scp:'|'^http:'
                exec a:editcmd.' '.fname
            else
                silent exec 'silent '.a:editcmd.' '.fname
            endif
        else " only happens in the Project File
            exec 'au! BufEnter,BufLeave '.expand('%:p')
        endif
        " Extract any CD information
        let c_d = s:GetCd(a:infoline, home)
        if c_d != '' && (s:IsAbsolutePath(home) != 2)
            if match(g:proj_flags, '\CL') != -1
                call s:SetupAutoCommand(c_d)
            endif
            if !isdirectory(glob(c_d))
                call confirm("From this fold's entry,\nCD=".'"'.c_d.'" is not a valid directory.', "&OK", 1)
            else
                silent exec cd_cmd.' '.c_d
            endif
        endif
        " Extract any scriptin information
        let scriptin = s:GetScriptin(a:infoline, home)
        if scriptin != ''
            if !filereadable(glob(scriptin))
                call confirm('"'.scriptin.'" not found. Ignoring.', "&OK", 1)
            else
                call s:SetupScriptAutoCommand('BufEnter', scriptin)
                exec 'source '.scriptin
            endif
        endif
        let scriptout = s:GetScriptout(a:infoline, home)
        if scriptout != ''
            if !filereadable(glob(scriptout))
                call confirm('"'.scriptout.'" not found. Ignoring.', "&OK", 1)
            else
                call s:SetupScriptAutoCommand('BufLeave', scriptout)
            endif
        endif
        return 1
    endfunction ">>>
    " s:DoFoldOrOpenEntry(cmd0, cmd1) <<<
    "   Used for <Enter> and double clicking.
    "   Open/close fold (directory), or open file.
    function! s:DoFoldOrOpenEntry(cmd0, cmd1)
        " (lb): Note to self: A right brace also ends the line$.
        " ~ ...ine('.') =~ '{\|}$' ...
        if getline('.') =~ '{\|}' || foldclosed('.') != -1
            normal! za
        else
            call s:DoEnsurePlacementSize_au()
            call s:OpenEntry(line('.'), a:cmd0, a:cmd1, 0)
            if (match(g:proj_flags, '\Cc') != -1)
                let g:proj_mywinnumber = winbufnr(0)
                Project
                hide
                if(g:proj_mywinnumber != winbufnr(0))
                    wincmd p
                endif
                wincmd =
            endif
        endif
    endfunction ">>>
    " s:VimDirListing(filter, exclude, padding, separator, filevariable, filecount, dirvariable, dircount) <<<
    "
    " SAVVY: Use `readdir` to generate a directory listing.
    " - HSTRY: Orig code used `glob`, e.g.,
    "     let l:filenames=glob(strpart(l:filters, 0, end))
    " - This has 2 drawbacks:
    "   - The result is a '\010'-byte separted string, rather than
    "     a List, and is not newline-friendly; also
    "   - The `glob` sorts by OS order, which is case-insensitive
    "     on @macOS, and the opposite on @Linux (e.g., @Linux sorts
    "     'UNCAPPED, capped' while @macOS sorts 'capped, UNCAPPED').
    "     - And if you maintain the same .vimprojects across OSes,
    "       this disparity might be annoying to you.
    " - So we'll used `readdir` instead, which lets us pick a sort
    "   order; it also returns a List. However, the {expr} chosen
    "   below uses regex, not glob syntax, e.g., =~ '.rst' won't
    "   work, we'd want =~ '.*\.rst' instead. So we need to convert.
    "   - Note that these two are similar:
    "       readdir(dirname, {n -> n =~ '\.rst'})
    "       readdir(dirname, {n -> n =~ '.*\.rst'})
    "     Whereas this is a little stricter:
    "       readdir(dirname, {n -> n =~ '.*\.rst$'})
    "     And that glob behaves like the *stricter* example,
    "     e.g., the glob '*.rst' is like '.*\.rst$' (or more
    "     simply '\.rst$').
    " - Note there's obviously a different {expr} we could use that
    "   does a glob-like compare. But the {expr} below is based on
    "   the example from the Vim help; which is now working with a
    "   (relatively) simple glob-to-regex conversion, so why change it.
    " SAVVY: List advantages:
    " - We don't have to 'guess' how to split up the `glob` response.
    "   - Ha! Consider this old `glob` parse code, where fnames is
    "     originally set to the `glob` output:
    "       let fname = substitute(fnames,  '\(\(\f\|[ :\[\]]\)*\).*', '\1', '')
    "       let fnames = substitute(fnames, '\(\f\|[ :\[\]]\)*.\(.*\)', '\2', '')
    "     - Here you see \f which uses `isfname` to split on filename boundaries.
    "       - But this approach often fails, e.g., it might replace '@' and '!'
    "         characters with newlines (so a file named 'bar@baz' would get
    "         listed as two files, 'bar' and 'baz', or a file named 'foo!'
    "         would get listed as 'foo' followed by a blank line).
    "       - The user could support @-names by dropping '@' from isfname, e.g.,
    "           set isfname=48-57,/,.,-,_,+,,,#,$,%,~,=,{,},(,),!,'
    "         But now we're talking weeds.
    " - INERT/2024-04-27: FTREQ: Support regex 'filter' and 'exclude' syntax.
    "   - INERT: Futile unless there's something glob syntax can't do.
    "
    function! s:VimDirListing(filter, exclude, padding, separator, filevariable, filecount, dirvariable, dircount)
        let l:files = []

        let l:filters = a:filter
        let l:end = 0

        " SAVVY: @macOS glob() sorts like 'icase'; @Linux like 'case'.
        let l:readdir_sort = 'case'
        if (exists("g:proj_sort"))
          let l:readdir_sort = g:proj_sort
        endif

        " Loop over individual filter expressions.
        " - Historically because glob() does not accept mult. expressions,
        "   e.g., `glob('*.c *.h')` won't work.
        " - Now because readdir() uses a callback function, and processing
        "   filter expressions one at a time seems simpler.
        let while_var = 1
        while while_var
            let end = stridx(l:filters, ' ')
            if end == -1
                let end = strlen(l:filters)
                let while_var = 0
            endif
            let l:filter = strpart(l:filters, 0, l:end)

            " 2024-04-27: Unsure this hits, but never assume?
            if (l:filter == '')
                continue
            endif

            " Glob-to-regex conversion: Emulate glob using re syntax.
            " - Convert periods to '\.'
            " - Add leading '^' unless starts with '*'
            " - Add trailing '$' unless ends with '*'
            " - Convert non-leading asterisks to '.*'
            " - Convert leading asterisks to '^[^.]\\{-}.*'
            "     using \{-} non-greedy match to leave the leading
            "       char alone
            " - Don't pass raw `~` aka 'latest substitute string' regexp token
            let l:refilter = ""
            if l:filter == '*'
              let l:refilter = "^[^.].*"
            elseif l:filter == '.*'
              let l:refilter = "^\\..*"
            else
              let l:refilter = substitute(
                \ substitute(
                \   substitute(
                \     substitute(
                \       substitute(
                \         substitute(
                \           l:filter, '\.', '\\\.', 'g'),
                \         '^\([^*]\)', '\^\1', ''),
                \       '\([^*]\)$', '\1\$', ''),
                \     '\([^^]\)\*', '\1\.*', 'g'),
                \   '^\*', '^[^.]\\{-}.*', 'g'),
                \ '\~', '\\\~', 'g')
            endif

            " CPYST- Demo previous call:
            "   :echo substitute(substitute(substitute(substitute(substitute(substitute('*', '\.', '\\\.', 'g'), '^\([^*]\)', '\^\1', ''), '\([^*]\)$', '\1\$', ''), '\([^^]\)\*', '\1\.*', 'g'), '^\*', '^[^.]\\{-}.*', 'g'), '\~', '\\\~', 'g')

            " DEV- Uncomment to print trace, e.g.,
            "   filter: .* / refilter: ^\..*
            "   filter: * / refilter: ^[^.].*
            "
            " echom 'filter: ' . l:filter . ' / refilter: ' . l:refilter
            " " Flush (odd, the last echom not always echoed before the
            " " pause; though it appears in a later :messages)
            " echom ""

            if has('nvim')
                " DUNNO: Did nvim remove 3rd arg ({ sort: }) ), or
                "        was it added to vim after nvim forked?
                let l:filter_files = readdir('.', {n -> n =~ l:refilter})
            else
                let l:filter_files = readdir('.', {n -> n =~ l:refilter}, #{sort: l:readdir_sort})
            endif

            let l:files += l:filter_files

            let l:filters = strpart(l:filters, end + 1)
        endwhile

        " The files var contains all files, dirs, and symlinks in the directory.

        " - Note that the project plugin historically just concatenated the
        "   results from each filter.
        "   - This lets the user impose somewhat of an order on files.
        "   - It also allows duplicate listings, if the filter expressions
        "     have overlapping results.
        " - Users can now opt-in to deduplicate files.
        if exists("g:proj_unique") && (g:proj_unique == 1)
          let l:files = uniq(sort(l:files))
        endif

        let {a:filevariable}=''
        let {a:dirvariable}=''
        let {a:filecount}=0
        let {a:dircount}=0
        for fname in l:files
            if (fname == '.') || (fname == "..")
                continue
            endif

            let exclude = a:exclude
            let ignore = 0
            let while_var = 1
            let end = 0

            if strlen(exclude) > 0
                while while_var
                    let end = stridx(exclude, ' ')
                    if end == -1
                        let end = strlen(exclude)
                        let while_var = 0
                    endif
                    let single = substitute(strpart(exclude, 0, end), '*', '', '')
                    let exclude = strpart(exclude, end + 1)
                    if fname=~?single.'$'
                        let ignore = 1
                        break
                    endif
                endwhile
            endif

            if ignore == 0
                if isdirectory(glob(fname))
                    " 2018-03-05: Not if symlink directory? Uncomment if you want.
                    " I'd rather not hide files except deliberately, and I don't
                    " want to hack in a new exclude option, so for now it's up to
                    " dev to enable this on an ad-hoc basis.
                    if g:plugin_dubs_project_skip_symlink_dirs
                        let ftype = getftype(glob(fname))
                        if ftype == "link"
                            echon "Skipping symlink: " . fname . "\r"

                            continue
                        endif
                    endif
                    " 2018-03-05: Seems only fitting. Ignore dir with:
                    "   cd dir/to/ignore
                    "   touch .dubs_project.vim-ignore
                    " See :help dos-backslash -- it says to use normal / separator.
                    let l:subfnames = glob(fname . "/.dubs_project.vim-ignore", 0, 1)
                    if len(l:subfnames) > 0
                        echon "Skipping ignored: " . fname . "\r"

                        continue
                    endif
                    " Bah. I'd rather not encode business logic herein, but whatever.
                    " 2022-12-07: At least this code tries to be smart about it:
                    " - When possible, verify the directory being ignored (e.g.,
                    "   .git/) is the thing you think it is (e.g., Git plumbing).
                    if fname == ".git"
                        " Verify Git artifact.
                        let l:subfnames = glob(fname . "/HEAD", 0, 1)
                        if len(l:subfnames) > 0
                            echon "Skipping .git: " . getcwd() . "/" . fname . "\r"

                            continue
                        endif
                    elseif fname == "htmlcov"
                        " Verify `python -m coverage` artifact.
                        let l:subfnames = glob(fname . "/.gitignore", 0, 1)
                        if len(l:subfnames) > 0
                            let l:gitignore = l:subfnames[0]
                            let l:firstlines = readfile(l:gitignore, "", 1)
                            if l:firstlines[0] == "# Created by coverage.py"
                              echon "Skipping htmlcov: " . getcwd() . "/" . fname . "\r"

                              continue
                            endif
                        endif
                    elseif fname == ".pytest_cache"
                        " Verify `python -m pytest` artifact.
                        let l:subfnames = glob(fname . "/.gitignore", 0, 1)
                        if len(l:subfnames) > 0
                            let l:gitignore = l:subfnames[0]
                            let l:firstlines = readfile(l:gitignore, "", 1)
                            if l:firstlines[0] == "# Created by pytest automatically."
                              echon "Skipping .pytest_cache: " . getcwd() . "/" . fname . "\r"

                              continue
                            endif
                        endif
                    " USYNC: Similar ignore lists (in 3 different DepoXy projects):
                    "   ~/.depoxy/ambers/home/.projlns/infuse-projlns-omr.sh
                    "   ~/.homefries/lib/alias/alias_fd.sh
                    "   ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project.vim
                    elseif fname == "node_modules"
                      \ || fname == ".nyc_output"
                      \ || fname == "__pycache__"
                      \ || fname == "site-packages"
                      \ || fname == ".tox"
                      \ || fname =~ "\\.venv.*"
                      \ || fname == ".vscode"
                      echon "Skipping generated/cache/packages dir: " . fname . "\r"

                      continue
                    endif

                    let {a:dirvariable}={a:dirvariable}.a:padding.fname.a:separator
                    let {a:dircount}={a:dircount} + 1
                else
                    let {a:filevariable}={a:filevariable}.a:padding.fname.a:separator
                    let {a:filecount}={a:filecount} + 1
                endif
            endif
        endfor
    endfunction ">>>
    " s:GenerateEntry(...) <<<
    function! s:GenerateEntry(recursive, line, name, absolute_dir, dir, c_d, filter_directive, filter, exclude_directive, exclude, foldlev, sort, first_line)
        let line=a:line
        if a:dir =~ '\\ '
            let dir='"'.substitute(a:dir, '\\ ', ' ', 'g').'"'
        else
            let dir=a:dir
        endif
        let spaces=strpart('                                                             ', 0, a:foldlev)
        let c_d=(strlen(a:c_d) > 0) ? 'CD='.a:c_d.' ' : ''
        let c_d=(strlen(a:filter_directive) > 0) ? c_d.'filter="'.a:filter_directive.'" ': c_d
        let c_d=(strlen(a:exclude_directive) > 0) ? c_d.'exclude="'.a:exclude_directive.'" ': c_d
        call append(line, spaces.'}')
        "call append(line, spaces.a:name.'='.dir.' '.c_d.'{')
        call append(line, spaces . a:name . '=' . a:absolute_dir . ' ' . c_d . '{')

        " 2017-10-16: [lb] seeing an unresponsive Vim when loading a big project.
        let on_line = a:line - a:first_line
        if 0 == on_line % 100
            echon "... on directory # " . on_line . "\r"
        endif

        if a:recursive
            exec 'cd '.a:absolute_dir
            " 2018-03-05: Missing dotdirectories!
            "call s:VimDirListing("*", '', '', "\010", 'b:files', 'b:filecount', 'b:dirs', 'b:dircount')
            " EXPLAIN/2018-03-05: What's "\010" separator?
            " :: s:VimDirListing(filter, exclude, padding, separator, filevariable, filecount, dirvariable, dircount)
            call s:VimDirListing(a:filter, a:exclude, '', "\010", 'b:files', 'b:filecount', 'b:dirs', 'b:dircount')
            cd -
            let dirs=b:dirs
            let dcount=b:dircount
            unlet b:files b:filecount b:dirs b:dircount
            while dcount > 0
                let dname = substitute(dirs,  '\(\( \|\f\|:\)*\).*', '\1', '')
                let edname = escape(dname, ' ')
                let dirs = substitute(dirs, '\( \|\f\|:\)*.\(.*\)', '\2', '')
                let line=s:GenerateEntry(1, line + 1, dname, a:absolute_dir.'/'.edname, edname, '', '', a:filter, '', a:exclude, a:foldlev+1, a:sort, a:first_line)
                let dcount=dcount-1
            endwhile
        endif
        return line+1
    endfunction " >>>
    " s:DoEntryFromDir(...) <<<
    "   Generate the fold from the directory hierarchy (if recursive), then
    "   fill it in with RefreshEntriesFromDir()
    function! s:DoEntryFromDir(recursive, line, name, absolute_dir, dir, c_d, filter_directive, filter, exclude_directive, exclude, foldlev, sort)
        call s:GenerateEntry(a:recursive, a:line, a:name, escape(a:absolute_dir, ' '), escape(a:dir, ' '), escape(a:c_d, ' '), a:filter_directive, a:filter, a:exclude_directive, a:exclude, a:foldlev, a:sort, a:line)
        normal! j
        call s:RefreshEntriesFromDir(1)
    endfunction ">>>
    " s:CreateEntriesFromDir(recursive) <<<
    "   Prompts user for information and then calls s:DoEntryFromDir()
    " 2015.01.08: [lb] changing function from searching recursively or not
    "             to asking too many questions or not.
    "  Orig: function! s:CreateEntriesFromDir(recursive)
    function! s:CreateEntriesFromDir(inquisitive)
        " Save a mark for the current cursor position
        normal! mk
        let line=line('.')
        let name = inputdialog('Enter the Name of the Entry: ')
        if strlen(name) == 0
            return
        endif
        let foldlev = s:get_correct_foldlevel(line)
        " [lb] Bracket also ends the line$.
        if (foldclosed(line) != -1) || (getline(line) =~ '}$')
            let foldlev=foldlev - 1
        endif
        let absolute = (foldlev <= 0)?'Absolute ': ''
        let home=''
        " 2018-03-05: Missing dotdirectories!
        "let filter='*'
        let filter='* .*'
        let exclude=''
        if (match(g:proj_flags, '\Cb') != -1) && has('browse')
            " Note that browse() is inconsistent: On Win32 you can't select a
            " directory, and it gives you a relative path.
            let dir = browse(0, 'Enter the '.absolute.'Directory to Load: ', '', '')
            let dir = fnamemodify(dir, ':p')
        else
            let dir = inputdialog('Enter the '.absolute.'Directory to Load: ', '')
        endif
        if (dir[strlen(dir)-1] == '/') || (dir[strlen(dir)-1] == '\\')
            let dir=strpart(dir, 0, strlen(dir)-1) " Remove trailing / or \
        endif
        let dir = substitute(dir, '^\~', $HOME, 'g')
        if (foldlev > 0)
            let parent_directive=s:RecursivelyConstructDirectives(line)
            let filter = s:GetFilter(parent_directive, '*')
            let exclude = s:GetExclude(parent_directive, '')
            let home=s:GetHome(parent_directive, '')
            if home[strlen(home)-1] != '/' && home[strlen(home)-1] != '\\'
                let home=home.'/'
            endif
            unlet parent_directive
            if s:IsAbsolutePath(dir)
                " It is not a relative path  Try to make it relative
                let hend=matchend(dir, '\C'.glob(home))
                if hend != -1
                    let dir=strpart(dir, hend)          " The directory can be a relative path
                else
                    let home=""
                endif
            endif
        endif
        if strlen(home.dir) == 0
            return
        endif
        if !isdirectory(home.dir)
            if has("unix")
                silent exec '!mkdir '.home.dir.' > /dev/null'
            else
                call confirm('"'.home.dir.'" is not a valid directory.', "&OK", 1)
                return
            endif
        endif

        " 2015.01.08: [lb] only ever completes the first two dialog
        "             boxes, so disabling the rest.
        " MAYBE/2017-10-16: Maybe I should show these things... though I
        "             never use CD (what does it do?) nor exclude.
        let c_d = ''
        " 2017-10-16: It's more obvious to user how to hide hidden files if
        " we initially include them, otherwise `filter=...` is excluded, and
        " user gets frustrated when they finally realize not all files are
        " being shown.
        "let filter_directive = ''
        let filter_directive = '.* *'
        let exclude_directive = ''

        " [lb] Default to recursive enabled, so \c is recursive.
        let recursive = 1

        if a:inquisitive == 1
          let c_d = inputdialog('Enter the CD parameter: ', '')
          let filter_directive = inputdialog('Enter the File Filter: ', '')
          if strlen(filter_directive) != 0
              let filter = filter_directive
          endif
          let exclude_directive = inputdialog('Enter the Exclude files: ', '')
          if strlen(exclude_directive) != 0
              let exclude = exclude_directive
          endif
          " NOTE: You have to use double-quotes for the {choices}.
          let recursive = confirm("Search Recursively?", "&Yes\n&No\n&Always")
          if recursive == 2
              " "No."
              let recursive = 0
          else
              let recursive = 1
          endif
        endif
        " If I'm on a closed fold, go to the bottom of it
        if foldclosedend(line) != -1
            let line = foldclosedend(line)
        endif
        let foldlev = s:get_correct_foldlevel(line)
        " If we're at the end of a fold . . .
        " [lb] Bracket also ends the line$.
        if getline(line) =~ '}$'
            let foldlev = foldlev - 1           " . . . decrease the indentation by 1.
        endif
        " Do the work
        call s:DoEntryFromDir(l:recursive, line, name, home.dir, dir, c_d, filter_directive, filter, exclude_directive, exclude, foldlev, 0)
        " Restore the cursor position
        normal! `k
    endfunction ">>>
    " s:RefreshEntriesFromDir(recursive) <<<
    "   Finds metadata at the top of the fold, and then replaces all files
    "   with the contents of the directory.  Works recursively if recursive is 1.
    function! s:RefreshEntriesFromDir(recursive)
        if s:get_correct_foldlevel('.') == 0
            echo 'Nothing to refresh.'
            return
        endif
        " Open the fold.
        " [lb] Bracket also ends the line$.
        if getline('.') =~ '}$'
            normal! zo[z
        else
            normal! zo]z[z
        endif
        let just_a_fold=0
        let infoline = s:RecursivelyConstructDirectives(line('.'))
        let immediate_infoline = getline('.')
        if strlen(substitute(immediate_infoline, '[^=]*=\(\(\f\|:\|\\ \)*\).*', '\1', '')) == strlen(immediate_infoline)
            let just_a_fold = 1
        endif
        " Extract the home directory of the fold
        let home = s:GetHome(infoline, '')
        if home == ''
            " No Match.  This means that this is just a label with no
            " directory entry.
            if a:recursive == 0
                return          " We're done--nothing to do
            endif
            " Mark that it is just a fold, so later we don't delete filenames
            " that aren't there.
            let just_a_fold = 1
        endif
        if just_a_fold == 0
            " Extract the filter between quotes (we don't care what CD is).
            let filter = s:GetFilter(infoline, '*')
            let exclude = s:GetExclude(infoline, '')
            " Extract the description (name) of the fold
            let name = substitute(infoline, '^[#\t ]*\([^=]*\)=.*', '\1', '')
            if strlen(name) == strlen(infoline)
                " If there's no name, we're done.
                return
            endif
            if (home == '') || (name == '')
                return
            endif
            " Extract the flags
            let flags = s:GetFlags(immediate_infoline)
            let sort = (match(g:proj_flags, '\CS') != -1)
            if flags != ''
                if match(flags, '\Cr') != -1
                    " If the flags do not contain r (refresh), then treat it just
                    " like a fold
                    let just_a_fold = 1
                endif
                if match(flags, '\CS') != -1
                    let sort = 1
                endif
                if match(flags, '\Cs') != -1
                    let sort = 0
                endif
            else
                let flags=''
            endif
        endif
        " Fix the opening bracket line indent.
        call s:RedentFoldPrefix()
        " Move to the first non-fold boundary line
        normal! j
        " Delete filenames until we reach the end of the fold
        " [lb] Bracket also ends the line$.
        while getline('.') !~ '}$'
            if line('.') == line('$')
                break
            endif
            " [lb] Bracket also ends the line$.
            if getline('.') !~ '{$'
                " We haven't reached a sub-fold, so delete what's there.
                if (just_a_fold == 0) && (getline('.') !~ '^\s*#') && (getline('.') !~ '#.*pragma keep')
                    d _
                else
                    " Skip lines only in a fold and comment lines
                    normal! j
                endif
            else
                " We have reached a sub-fold. If we're doing recursive, then
                " call this function again. If not, find the end of the fold.
                if a:recursive == 1
                    call s:RefreshEntriesFromDir(1)
                    normal! ]zj
                else
                    if foldclosed('.') == -1
                        normal! zc
                    endif
                    normal! j
                endif
            endif
        endwhile
        " Fix the closing bracket line indent.
        if getline('.') =~ '}$'
            call s:RedentFoldPrefix()
        endif
        if just_a_fold == 0
            " We're not just in a fold, and we have deleted all the filenames.
            " Now it is time to regenerate what is in the directory.
            if !isdirectory(glob(home))
                call confirm('"'.home.'" is not a valid directory.', "&OK", 1)
            else
                let foldlev=s:get_correct_foldlevel('.')
                " T flag.  Thanks Tomas Z.
                if (match(flags, '\Ct') != -1) || ((match(g:proj_flags, '\CT') == -1) && (match(flags, '\CT') == -1))
                    " Go to the top of the fold (force other folds to the
                    " bottom)
                    normal! [z
                    normal! j
                    " Skip any comments
                    while getline('.') =~ '^\s*#'
                        normal! j
                    endwhile
                endif
                normal! k
                let cwd=getcwd()
                let spaces=strpart('                                               ', 0, foldlev)
                exec 'cd '.home
                if match(g:proj_flags, '\Ci') != -1
                    echon home."\r"
                endif
                call s:VimDirListing(filter, exclude, spaces, "\n", 'b:files', 'b:filecount', 'b:dirs', 'b:dircount')
                if b:filecount > 0
                    normal! mk
                    silent! put =b:files
                    normal! `kj
                    if sort
                        call s:SortR(line('.'), line('.') + b:filecount - 1)
                    endif
                else
                    normal! j
                endif
                unlet b:files b:filecount b:dirs b:dircount
                exec 'cd '.cwd
            endif
        endif
        " Go to the top of the refreshed fold.
        normal! [z
    endfunction ">>>
    " s:RedentFoldPrefix() <<<
    "   Sets the whitespce fold or unfold ('{' and '}' lines) indent
    function! s:RedentFoldPrefix()
        let l:foldlev = s:get_correct_foldlevel('.')
        " A trick to basically `' ' * foldlev`, take substring of long spacestring:
        let l:spaces=strpart('                                               ', 0, l:foldlev - 1)
        exec '.s/^\s*/' . l:spaces . '/'
    endfunction ">>>
    " s:MoveUp() <<<
    "   Moves the entity under the cursor up a line.
    function! s:MoveUp()
        let lineno=line('.')
        if lineno == 1
            return
        endif
        let fc=foldclosed('.')
        let a_reg=@a
        if lineno == line('$')
            normal! "add"aP
        else
            normal! "addk"aP
        endif
        let @a=a_reg
        if fc != -1
            normal! zc
        endif
    endfunction ">>>
    " s:MoveDown() <<<
    "   Moves the entity under the cursor down a line.
    function! s:MoveDown()
        let fc=foldclosed('.')
        let a_reg=@a
        normal! "add"ap
        let @a=a_reg
        if (fc != -1) && (foldclosed('.') == -1)
            normal! zc
        endif
    endfunction " >>>
    " s:DisplayInfo() <<<
    "   Displays filename and current working directory when i (info) is in
    "   the flags.
    function! s:DisplayInfo()
        if match(g:proj_flags, '\Ci') != -1
            " Print message after user double-clicks a file to open.
            " - Note than `echo` here causes Vim to prompt for acknowledgment:
            "     echo 'file: '.expand('%').', cwd: '.getcwd().', lines: '.line('$')
            "   But using `echon` doesn't provoke confirmation prompt.
            echon 'file: '.expand('%').', cwd: '.getcwd().', lines: '.line('$')."\r"
        endif
    endfunction ">>>
    " s:SetupAutoCommand(cwd) <<<
    "   Sets up an autocommand to ensure that the cwd is set to the one
    "   desired for the fold regardless.  :lcd only does this on a per-window
    "   basis, not a per-buffer basis.
    function! s:SetupAutoCommand(cwd)
        if !exists("b:proj_has_autocommand")
            let b:proj_cwd_save = escape(getcwd(), ' ')
            let b:proj_has_autocommand = 1
            let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
            exec 'au BufEnter '.bufname." let b:proj_cwd_save=escape(getcwd(), ' ') | cd ".a:cwd
            exec 'au BufLeave '.bufname.' exec "cd ".b:proj_cwd_save'
            exec 'au BufWipeout '.bufname.' au! * '.bufname
        endif
    endfunction ">>>
    " s:SetupScriptAutoCommand(bufcmd, script) <<<
    "   Sets up an autocommand to run the scriptin script.
    function! s:SetupScriptAutoCommand(bufcmd, script)
        if !exists("b:proj_has_".a:bufcmd)
            let b:proj_has_{a:bufcmd} = 1
            exec 'au '.a:bufcmd.' '.escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ').' source '.a:script
        endif
    endfunction " >>>
    " s:DoEnsurePlacementSize_au() <<<
    "   Ensure that the Project window is on the left of the window and has
    "   the correct size. Only called from an autocommand
    function! s:DoEnsurePlacementSize_au()
        if ((exists("g:proj_running") && (winbufnr(0) != g:proj_running)) 
            \ || (winnr() != 1))
            " ISOFF: The g:proj_doinghelp mechanism is never enabled.
            if exists("g:proj_doinghelp")
                if g:proj_doinghelp > 0
                    let g:proj_doinghelp = g:proj_doinghelp - 1
                    return
                endif
                unlet g:proj_doinghelp
                return
            endif
            exec b:proj_locate_command
        endif
        exec b:proj_resize_command
    endfunction ">>>
    " s:Spawn(number) <<<
    "   Spawn an external command on the file
    function! s:Spawn(number)
        echo | if exists("g:proj_run".a:number)
            let fname=getline('.')
            " [lb] Bracket also ends the line$.
            if fname !~ '{\|}$'
                let fname=substitute(fname, '\s*#.*', '', '')
                let fname=substitute(fname, '^\s*\(.*\)\s*', '\1', '')
                if fname == '' | return | endif
                let parent_infoline = s:RecursivelyConstructDirectives(line('.'))
                let home=expand(s:GetHome(parent_infoline, ''))
                let c_d=expand(s:GetCd(parent_infoline, ''))
                let command=substitute(g:proj_run{a:number}, '%%', "\010", 'g')
                let command=substitute(command, '%f', escape(home.'/'.fname, '\'), 'g')
                let command=substitute(command, '%F', substitute(escape(home.'/'.fname, '\'), ' ', '\\\\ ', 'g'), 'g')
                let command=substitute(command, '%s', escape(home.'/'.fname, '\'), 'g')
                let command=substitute(command, '%n', escape(fname, '\'), 'g')
                let command=substitute(command, '%N', substitute(fname, ' ', '\\\\ ', 'g'), 'g')
                let command=substitute(command, '%h', escape(home, '\'), 'g')
                let command=substitute(command, '%H', substitute(escape(home, '\'), ' ', '\\\\ ', 'g'), 'g')
                if c_d != ''
                    if c_d == home
                        let percent_r='.'
                    else
                        let percent_r=substitute(home, escape(c_d.'/', '\'), '', 'g')
                    endif
                else
                    let percent_r=home
                endif
                let command=substitute(command, '%r', percent_r, 'g')
                let command=substitute(command, '%R', substitute(percent_r, ' ', '\\\\ ', 'g'), 'g')
                let command=substitute(command, '%d', escape(c_d, '\'), 'g')
                let command=substitute(command, '%D', substitute(escape(c_d, '\'), ' ', '\\\\ ', 'g'), 'g')
                let command=substitute(command, "\010", '%', 'g')
                exec command
            endif
        endif
    endfunction ">>>
    " s:ListSpawn(varnamesegment) <<<
    "   List external commands
    function! s:ListSpawn(varnamesegment)
        let number = 1
        while number < 10
            if exists("g:proj_run".a:varnamesegment.number)
                echohl LineNr | echo number.':' | echohl None | echon ' '.substitute(escape(g:proj_run{a:varnamesegment}{number}, '\'), "\n", '\\n', 'g')
            else
                echohl LineNr | echo number.':' | echohl None
            endif
            let number=number + 1
        endwhile
    endfunction ">>>
    " s:FindFoldTop(line) <<<
    "   Return the line number of the directive line
    function! s:FindFoldTop(line)
        let lineno=a:line
        " [lb] Bracket also ends the line$.
        if getline(lineno) =~ '}$'
            let lineno = lineno - 1
        endif
        " [lb] Bracket also ends the line$.
        while getline(lineno) !~ '{$' && lineno > 1
            if getline(lineno) =~ '}$'
                let lineno=s:FindFoldTop(lineno)
            endif
            let lineno = lineno - 1
        endwhile
        return lineno
    endfunction ">>>
    " s:FindFoldBottom(line) <<<
    "   Return the line number of the directive line
    function! s:FindFoldBottom(line)
        let lineno=a:line
        " [lb] Bracket also ends the line$.
        if getline(lineno) =~ '{$'
            let lineno=lineno + 1
        endif
        while getline(lineno) !~ '}$' && lineno < line('$')
            if getline(lineno) =~ '{$'
                let lineno=s:FindFoldBottom(lineno)
            endif
            let lineno = lineno + 1
        endwhile
        return lineno
    endfunction ">>>
    " s:LoadAll(recurse, line) <<<
    "   Load all files in a project
    function! s:LoadAll(recurse, line)
        let b:loadcount=0
        function! s:SpawnExec(infoline, fname, lineno, data)
            if s:OpenEntry2(a:lineno, a:infoline, a:fname, 'e')
                wincmd p
                let b:loadcount=b:loadcount+1
                echon b:loadcount."\r"
                if getchar(0) != 0
                    let b:stop_everything=1
                endif
            endif
        endfunction
        call Project_ForEach(a:recurse, line('.'), "*<SID>SpawnExec", 0, '^\(.*l\)\@!')
        delfunction s:SpawnExec
        echon b:loadcount." Files Loaded\r"
        unlet b:loadcount
        if exists("b:stop_everything") | unlet b:stop_everything | endif
    endfunction ">>>
    " s:WipeAll(recurse, line) <<<
    "   Wipe all files in a project
    function! s:WipeAll(recurse, line)
        let b:wipecount=0
        let b:totalcount=0
        function! s:SpawnExec(home, c_d, fname, lineno, data)
            let fname=escape(a:fname, ' ')
            if s:IsAbsolutePath(fname)
                let fname=fnamemodify(fname, ':n')  " :n is coming, won't break anything now
            else
                let fname=fnamemodify(a:home.'/'.fname, ':n')  " :n is coming, won't break anything now
            endif
            let b:totalcount=b:totalcount+1
            let fname=substitute(fname, '^\~', $HOME, 'g')
            if bufloaded(substitute(fname, '\\ ', ' ', 'g'))
                if getbufvar(fname.'\>', '&modified') == 1
                    exec 'sb '.fname
                    wincmd L
                    w
                    wincmd p
                endif
                let b:wipecount=b:wipecount+1
                exec 'bwipe! '.fname
            endif
            if b:totalcount % 5 == 0
                echon b:wipecount.' of '.b:totalcount."\r"
                redraw
            endif
            if getchar(0) != 0
                let b:stop_everything=1
            endif
        endfunction
        call Project_ForEach(a:recurse, line('.'), "<SID>SpawnExec", 0, '^\(.*w\)\@!')
        delfunction s:SpawnExec
        echon b:wipecount.' of '.b:totalcount." Files Wiped\r"
        unlet b:wipecount b:totalcount
        if exists("b:stop_everything") | unlet b:stop_everything | endif
    endfunction ">>>
    " s:LoadAllSplit(recurse, line) <<<
    "   Load all files in a project using split windows.
    "   Contributed by A. Harrison
    function! s:LoadAllSplit(recurse, line)
        let b:loadcount=0
        function! s:SpawnExec(infoline, fname, lineno, data)
            let winNr = winnr() "get ProjectWindow number
            if s:OpenEntry2(a:lineno, a:infoline, a:fname, 'sp')
                exec winNr."wincmd w"
                let b:loadcount=b:loadcount+1
                echon b:loadcount."\r"
                if getchar(0) != 0
                    let b:stop_everything=1
                endif
            endif
        endfunction
        call Project_ForEach(a:recurse, line('.'), "*<SID>SpawnExec", 0, '^\(.*l\)\@!')
        delfunction s:SpawnExec
        echon b:loadcount." Files Loaded\r"
        unlet b:loadcount
        if exists("b:stop_everything") | unlet b:stop_everything | endif
    endfunction ">>>
    " s:GrepAll(recurse, lineno, pattern) <<<
    "   Grep all files in a project, optionally recursively
    function! s:GrepAll(recurse, lineno, pattern)
        silent! cunmap <buffer> help
        let pattern=(a:pattern[0] == '')?input("GREP options and pattern: "):a:pattern
        " 2018-05-06: (lb): See comment below/elsewhere: Disable 'help' mapping,
        " because it interferes with /-search.
        "  cnoremap <buffer> help let g:proj_doinghelp = 1<CR>:help
        if pattern[0] == ''
            return
        endif
        let b:escape_spaces=1
        let fnames=Project_GetAllFnames(a:recurse, a:lineno, ' ')
        unlet b:escape_spaces
        cclose " Make sure grep window is closed
        call s:DoSetupAndSplit()
        if match(g:proj_flags, '\Cv') == -1
            " Don't open first match be default if B flag enabled.
            let l:bang = ''
            if match(g:proj_flags, '\CB') != -1
                let l:bang = '!'
            endif
            " Note in Neovim, default grepprg is `rg --vimgrep -uu`.
            " - On classic Vim, it's `grep -n $* /dev/null`
            silent! exec 'silent! grep'.l:bang.' '.pattern.' '.fnames
            if v:shell_error != 0
                echo 'GREP error. Perhaps there are too many filenames.'
            elseif match(g:proj_flags, '\CB') != -1
                botright copen
            else
                copen
            endif
        else
            silent! exec 'silent! vimgrep '.pattern.' '.fnames
            if match(g:proj_flags, '\CB') != -1
                botright copen
            else
                copen
            endif
        endif
    endfunction ">>>
    " GetXXX Functions <<<
    function! s:GetHome(info, parent_home)
        " Thanks to Adam Montague for pointing out the need for @ in urls.
        let home=substitute(a:info, '^[^=]*=\(\(\\ \|\f\|:\|@\)\+\).*', '\1', '')
        if strlen(home) == strlen(a:info)
            let home=substitute(a:info, '.\{-}"\(.\{-}\)".*', '\1', '')
            if strlen(home) != strlen(a:info) | let home=escape(home, ' ') | endif
        endif
        if strlen(home) == strlen(a:info)
            let home=a:parent_home
        elseif home=='.'
            let home=a:parent_home
        elseif !s:IsAbsolutePath(home)
            let home=a:parent_home.'/'.home
        endif
        return home
    endfunction
    function! s:GetFilter(info, parent_filter)
        let filter = substitute(a:info, '.*\<filter="\([^"]\{-}\)".*', '\1', '')
        if strlen(filter) == strlen(a:info) | let filter = a:parent_filter | endif
        return filter
    endfunction
    function! s:GetExclude(info, parent_exclude)
        let exclude = substitute(a:info, '.*\<exclude="\([^"]\{-}\)".*', '\1', '')
        if strlen(exclude) == strlen(a:info) | let exclude = a:parent_exclude | endif
        " Default-ignore macOS Finder .DS_Store files (which author assumes
        " no user anywhere will ever care about).
        " - SAVVY: If there's an extraneous/extra space, everything is excluded,
        "   so only add space if exclude nonempty.
        if strlen(exclude) > 0 | let exclude = exclude .. " " | endif
        let exclude = exclude .. ".DS_Store"
        return exclude
    endfunction
    function! s:GetCd(info, home)
        let c_d=substitute(a:info, '.*\<CD=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
        if strlen(c_d) == strlen(a:info)
            let c_d=substitute(a:info, '.*\<CD="\(.\{-}\)".*', '\1', '')
            if strlen(c_d) != strlen(a:info) | let c_d=escape(c_d, ' ') | endif
        endif
        if strlen(c_d) == strlen(a:info)
            let c_d=''
        elseif c_d == '.'
            let c_d = a:home
        elseif !s:IsAbsolutePath(c_d)
            let c_d = a:home.'/'.c_d
        endif
        return c_d
    endfunction
    function! s:GetScriptin(info, home)
        let scriptin = substitute(a:info, '.*\<in=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
        if strlen(scriptin) == strlen(a:info)
            let scriptin=substitute(a:info, '.*\<in="\(.\{-}\)".*', '\1', '')
            if strlen(scriptin) != strlen(a:info) | let scriptin=escape(scriptin, ' ') | endif
        endif
        if strlen(scriptin) == strlen(a:info) | let scriptin='' | else
        if !s:IsAbsolutePath(scriptin) | let scriptin=a:home.'/'.scriptin | endif | endif
        return scriptin
    endfunction
    function! s:GetScriptout(info, home)
        let scriptout = substitute(a:info, '.*\<out=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
        if strlen(scriptout) == strlen(a:info)
            let scriptout=substitute(a:info, '.*\<out="\(.\{-}\)".*', '\1', '')
            if strlen(scriptout) != strlen(a:info) | let scriptout=escape(scriptout, ' ') | endif
        endif
        if strlen(scriptout) == strlen(a:info) | let scriptout='' | else
        if !s:IsAbsolutePath(scriptout) | let scriptout=a:home.'/'.scriptout | endif | endif
        return scriptout
    endfunction
    function! s:GetFlags(info)
        let flags=substitute(a:info, '.*\<flags=\([^ {]*\).*', '\1', '')
        if (strlen(flags) == strlen(a:info))
            let flags=''
        endif
        return flags
    endfunction ">>>
    " Project_GetAllFnames(recurse, lineno, separator) <<<
    "   Grep all files in a project, optionally recursively
    function! Project_GetAllFnames(recurse, lineno, separator)
        let b:fnamelist=''
        function! s:SpawnExec(home, c_d, fname, lineno, data)
            if exists('b:escape_spaces')
                let fname=escape(a:fname, ' ')
            else
                let fname=a:fname
            endif
            if !s:IsAbsolutePath(a:fname)
                let fname=a:home.'/'.fname
            endif
            let b:fnamelist=b:fnamelist.a:data.fname
        endfunction
        call Project_ForEach(a:recurse, line('.'), "<SID>SpawnExec", a:separator, '')
        delfunction s:SpawnExec
        let retval=b:fnamelist
        unlet b:fnamelist
        return retval
    endfunction ">>>
    " Project_GetAllFnames(recurse, lineno, separator) <<<
    "   Grep all files in a project, optionally recursively
    function! Project_GetFname(line)
        if (s:get_correct_foldlevel(a:line) == 0)
            return ''
        endif
        let fname=substitute(getline(a:line), '\s*#.*', '', '') " Get rid of comments and whitespace before comment
        let fname=substitute(fname, '^\s*\(.*\)', '\1', '') " Get rid of leading whitespace
        if strlen(fname) == 0
            return ''                    " The line is blank. Do nothing.
        endif
        if s:IsAbsolutePath(fname)
            return fname
        endif
        let infoline = s:RecursivelyConstructDirectives(a:line)
        return s:GetHome(infoline, '').'/'.fname
    endfunction ">>>
    " Project_ForEach(recurse, lineno, cmd, data, match) <<<
    "   Grep all files in a project, optionally recursively
    function! Project_ForEach(recurse, lineno, cmd, data, match)
        let info=s:RecursivelyConstructDirectives(a:lineno)
        let lineno=s:FindFoldTop(a:lineno) + 1
        let flags=s:GetFlags(getline(lineno - 1))
        if (flags == '') || (a:match=='') || (match(flags, a:match) != -1)
            call s:Project_ForEachR(a:recurse, lineno, info, a:cmd, a:data, a:match)
        endif
    endfunction
    function! s:Project_ForEachR(recurse, lineno, info, cmd, data, match)
        let home=s:GetHome(a:info, '')
        let c_d=s:GetCd(a:info, home)
        let scriptin = s:GetScriptin(a:info, home)
        let scriptout = s:GetScriptout(a:info, home)
        let filter = s:GetFilter(a:info, '')
        let exclude = s:GetExclude(a:info, '')
        let lineno = a:lineno
        let curline=getline(lineno)
        " [lb] Bracket also ends the line$.
        while (curline !~ '}$') && (curline < line('$'))
            if exists("b:stop_everything") && b:stop_everything | return 0 | endif
            if curline =~ '{$'
                if a:recurse
                    let flags=s:GetFlags(curline)
                    if (flags == '') || (a:match=='') || (match(flags, a:match) != -1)
                        let this_home=s:GetHome(curline, home)
                        let this_cd=s:GetCd(curline, this_home)
                        if this_cd=='' | let this_cd=c_d | endif
                        let this_scriptin=s:GetScriptin(curline, this_home)
                        if this_scriptin == '' | let this_scriptin=scriptin | endif
                        let this_scriptout=s:GetScriptin(curline, this_home)
                        if this_scriptout == '' | let this_scriptout=scriptout | endif
                        let this_filter=s:GetFilter(curline, filter)
                        let this_exclude=s:GetExclude(curline, exclude)
                        let lineno=s:Project_ForEachR(1, lineno+1,
                            \s:ConstructInfo(this_home, this_cd, this_scriptin, this_scriptout, flags, this_filter, this_exclude), a:cmd, a:data, a:match)
                    else
                        let lineno=s:FindFoldBottom(lineno)
                    endif
                else
                    let lineno=s:FindFoldBottom(lineno)
                endif
            else
                let fname=substitute(curline, '\s*#.*', '', '')
                let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
                if (strlen(fname) != strlen(curline)) && (fname[0] != '')
                    if a:cmd[0] == '*'
                        call {strpart(a:cmd, 1)}(a:info, fname, lineno, a:data)
                    else
                        call {a:cmd}(home, c_d, fname, lineno, a:data)
                    endif
                endif
            endif
            let lineno=lineno + 1
            let curline=getline(lineno)
        endwhile
        return lineno
    endfunction ">>>
    " s:SpawnAll(recurse, number) <<<
    "   Spawn an external command on the files of a project
    function! s:SpawnAll(recurse, number)
        echo | if exists("g:proj_run_fold".a:number)
            if g:proj_run_fold{a:number}[0] == '*'
                function! s:SpawnExec(home, c_d, fname, lineno, data)
                    let command=substitute(strpart(g:proj_run_fold{a:data}, 1), '%s', escape(a:fname, ' \'), 'g')
                    let command=substitute(command, '%f', escape(a:fname, '\'), 'g')
                    let command=substitute(command, '%h', escape(a:home, '\'), 'g')
                    let command=substitute(command, '%d', escape(a:c_d, '\'), 'g')
                    let command=substitute(command, '%F', substitute(escape(a:fname, '\'), ' ', '\\\\ ', 'g'), 'g')
                    exec command
                endfunction
                call Project_ForEach(a:recurse, line('.'), "<SID>SpawnExec", a:number, '.')
                delfunction s:SpawnExec
            else
                let info=s:RecursivelyConstructDirectives(line('.'))
                let home=s:GetHome(info, '')
                let c_d=s:GetCd(info, '')
                let b:escape_spaces=1
                let fnames=Project_GetAllFnames(a:recurse, line('.'), ' ')
                unlet b:escape_spaces
                let command=substitute(g:proj_run_fold{a:number}, '%f', substitute(escape(fnames, '\'), '\\ ', ' ', 'g'), 'g')
                let command=substitute(command, '%s', escape(fnames, '\'), 'g')
                let command=substitute(command, '%h', escape(home, '\'), 'g')
                let command=substitute(command, '%d', escape(c_d, '\'), 'g')
                let command=substitute(command, '%F', escape(fnames, '\'), 'g')
                exec command
                if v:shell_error != 0
                    echo 'Shell error. Perhaps there are too many filenames.'
                endif
            endif
        endif
    endfunction ">>>
    " Project has historically used <Space> as the width toggle, but some
    " (Neo)vim distros (e.g., LazyVim) and some users use <Space> as a
    " leader character. Let's not interfere.
    function! s:WidthToggleLhs()
        let l:lhs_width_toggle = '<space>'
        if g:mapleader == ' ' || vim.g.maplocalleader == ' '
            " Default <S-Space> appears same as |w| (but undocumented?).
            let l:lhs_width_toggle = get(g:, 'proj_width_toggle_lhs', '<s-space>')
        endif
        return l:lhs_width_toggle
    endfunction
    " Mappings <<<
    function! s:CreateMaps_ProjectBuffer()
        let l:width_toggle_lhs = s:WidthToggleLhs()

        nnoremap <buffer> <silent> <Return>   \|:call <SID>DoFoldOrOpenEntry('', 'e')<CR>
        nnoremap <buffer> <silent> <S-Return> \|:call <SID>DoFoldOrOpenEntry('', 'sp')<CR>
        nnoremap <buffer> <silent> <C-Return> \|:call <SID>DoFoldOrOpenEntry('silent! only', 'e')<CR>

        nnoremap <buffer> <silent> <LocalLeader>T \|:call <SID>DoFoldOrOpenEntry('', 'tabe')<CR>
        nmap     <buffer> <silent> <LocalLeader>s <S-Return>
        nnoremap <buffer> <silent> <LocalLeader>S \|:call <SID>LoadAllSplit(0, line('.'))<CR>
        nmap     <buffer> <silent> <LocalLeader>o <C-Return>
        nnoremap <buffer> <silent> <LocalLeader>i :echo <SID>RecursivelyConstructDirectives(line('.'))<CR>
        nnoremap <buffer> <silent> <LocalLeader>I :echo Project_GetFname(line('.'))<CR>

        nmap     <buffer> <silent> <M-CR> <Return><C-W>p
        nmap     <buffer> <silent> <LocalLeader>v <M-CR>

        nnoremap <buffer> <silent> <LocalLeader>l \|:call <SID>LoadAll(0, line('.'))<CR>
        nnoremap <buffer> <silent> <LocalLeader>L \|:call <SID>LoadAll(1, line('.'))<CR>
        nnoremap <buffer> <silent> <LocalLeader>w \|:call <SID>WipeAll(0, line('.'))<CR>
        nnoremap <buffer> <silent> <LocalLeader>W \|:call <SID>WipeAll(1, line('.'))<CR>
        nnoremap <buffer> <silent> <LocalLeader>g \|:call <SID>GrepAll(1, line('.'), "")<CR>
        nnoremap <buffer> <silent> <LocalLeader>G \|:call <SID>GrepAll(0, line('.'), "")<CR>

        nnoremap <buffer> <silent> <2-LeftMouse>   \|:call <SID>DoFoldOrOpenEntry('', 'e')<CR>
        " [lb] add insert mode mapping, too.
        inoremap <buffer> <silent> <2-LeftMouse>   <C-O>:call <SID>DoFoldOrOpenEntry('', 'e')<CR>
        nnoremap <buffer> <silent> <S-2-LeftMouse> \|:call <SID>DoFoldOrOpenEntry('', 'sp')<CR>
        nnoremap <buffer> <silent> <M-2-LeftMouse> <M-CR>
        nnoremap <buffer> <silent> <S-LeftMouse>   <LeftMouse>
        nmap     <buffer> <silent> <C-2-LeftMouse> <C-Return>
        nnoremap <buffer> <silent> <C-LeftMouse>   <LeftMouse>
        nnoremap <buffer> <silent> <3-LeftMouse>  <Nop>

        exec "nmap     <buffer> <silent> <RightMouse>   " .. l:width_toggle_lhs
        exec "nmap     <buffer> <silent> <2-RightMouse> " .. l:width_toggle_lhs
        exec "nmap     <buffer> <silent> <3-RightMouse> " .. l:width_toggle_lhs
        exec "nmap     <buffer> <silent> <4-RightMouse> " .. l:width_toggle_lhs
        exec "nnoremap <buffer> <silent> " .. l:width_toggle_lhs .. " \\|:silent exec 'vertical resize ' .. (match(g:proj_flags, '\\Ct') != -1 && winwidth('.') > g:proj_window_width ? g:proj_window_width : (winwidth('.') + g:proj_window_increment))" .. '<CR>'

        " 2021-01-31: (lb) The dubs_buffer_fun plugin maps Ctrl-Up/-Down to
        " scrolling the window up/down one line (without moving the cursor);
        " and it maps the Alt-Up/-Down combos to TmuxNavigateUp/Down.
        " - The origin project.vim C-Up/-Down maps shadow those from
        "   dubs_buffer_fun, but only in normal mode, which leads to an
        "   incongruity where C-Up/-Down work differently in the two modes
        "   in the project tray only.
        "     nnoremap <buffer> <silent> <C-Up>   \|:silent call <SID>MoveUp()<CR>
        "     nnoremap <buffer> <silent> <C-Down> \|:silent call <SID>MoveDown()<CR>
        "     nmap     <buffer> <silent> <LocalLeader><Up> <C-Up>
        "     nmap     <buffer> <silent> <LocalLeader><Down> <C-Down>
        " - I first looked into wiring Alt-Up/-Down instead, e.g.,
        "     nnoremap <buffer> <silent> <M-Up>   :call <SID>MoveUp()<CR>
        "     nnoremap <buffer> <silent> <M-Down> :call <SID>MoveDown()<CR>
        "     inoremap <buffer> <silent> <M-Up>   <C-O>:call <SID>MoveUp()<CR>
        "     inoremap <buffer> <silent> <M-Down> <C-O>:call <SID>MoveDown()<CR>
        "   But then in tmux if you've got a split pane, you cannot use
        "   Alt-Up/-Down to leave the project tray (it moves text instead).
        "   And I wasn't too keen on the peculiar change in behavior for that
        "   buffer (especially for something I rarely do, use the project tray
        "   in a tmux window split horizontally). I'd rather stay w/ C-Up/-Down.
        " - Then I realized that these maps don't need to use arrow keys, which
        "   are highly prized and coveted, and I mostly use them for moving the
        "   cursor around buffers, panes, and tabs, and not for moving text, so
        "   let's think outside the arrow box.
        "   - Another popular plugin, vim-buffer-ring, uses Ctrl-J/-K to change
        "     buffers, and it's disabled for special buffers, including project.
        "     Which means these keys are available for project.vim (and Ctrl-key
        "     maps are also highly prized combos, especially because Ctrl-key
        "     combos do not recognize case (so rather than 52 Ctrl-[[:alpha:]]
        "     combos, there are only 26).
        "       https://github.com/landonb/vim-buffer-ring#💍
        " - So rather than Ctrl-Up/-Down in Normal mode moving lines (and
        "   Ctrl-Up/-Down in Insert mode scrolling the buffer view, if
        "   dubs_buffer_fun is installed), let's wire Ctrl-J/-K in both
        "   Normal and Insert modes to moving line or fold under cursor
        "   up and down.
        "   - And note that I removed the \| (what's that do?) and the 'silent'
        "     (also what?) from the maps and didn't see a difference in behavior.
        nnoremap <buffer> <silent> <C-k> :call <SID>MoveUp()<CR>
        nnoremap <buffer> <silent> <C-j> :call <SID>MoveDown()<CR>
        inoremap <buffer> <silent> <C-k> <C-O>:call <SID>MoveUp()<CR>
        inoremap <buffer> <silent> <C-j> <C-O>:call <SID>MoveDown()<CR>
        " The complementary \-Up and \-Down maps, historical, but also
        " maybe easier to remember.
        nmap     <buffer> <silent> <LocalLeader><Up> <C-k>
        nmap     <buffer> <silent> <LocalLeader><Down> <C-j>
        imap     <buffer> <silent> <LocalLeader><Up> <C-O><C-k>
        imap     <buffer> <silent> <LocalLeader><Down> <C-O><C-j>

        let k=1
        while k < 10
            if exists("g:proj_run" .. l:k)
                exec 'nnoremap <buffer> <LocalLeader>'.k.'  \|:call <SID>Spawn('.k.')<CR>'
            endif
            if exists("g:proj_run_fold" .. l:k)
                exec 'nnoremap <buffer> <LocalLeader>f'.k.' \|:call <SID>SpawnAll(0, '.k.')<CR>'
                exec 'nnoremap <buffer> <LocalLeader>F'.k.' \|:call <SID>SpawnAll(1, '.k.')<CR>'
            endif
            let k=k+1
        endwhile
        nnoremap <buffer>          <LocalLeader>0 \|:call <SID>ListSpawn("")<CR>
        nnoremap <buffer>          <LocalLeader>f0 \|:call <SID>ListSpawn("_fold")<CR>
        nnoremap <buffer>          <LocalLeader>F0 \|:call <SID>ListSpawn("_fold")<CR>

        " 2015.01.08: [lb] only ever creates recursively, so redoing the
        "             mappings to make little 'c' use a less verbose
        "             setup wizard and to search recursively.
        "             That is, the 0 and 1 used to mean 'recursive', and
        "             now they mean 'verbose'. (They still mean 'recursive'
        "             for the refresh commands, though.)
        nnoremap <buffer> <silent> <LocalLeader>c :call <SID>CreateEntriesFromDir(0)<CR>
        nnoremap <buffer> <silent> <LocalLeader>C :call <SID>CreateEntriesFromDir(1)<CR>
        nnoremap <buffer> <silent> <LocalLeader>r :call <SID>RefreshEntriesFromDir(0)<CR>
        nnoremap <buffer> <silent> <LocalLeader>R :call <SID>RefreshEntriesFromDir(1)<CR>
        " For Windows users: same as \R
        nnoremap <buffer> <silent>           <F5> :call <SID>RefreshEntriesFromDir(1)<CR>
        nnoremap <buffer> <silent> <LocalLeader>e :call <SID>OpenEntry(line('.'), '', '', 0)<CR>
        nnoremap <buffer> <silent> <LocalLeader>E :call <SID>OpenEntry(line('.'), '', 'e', 1)<CR>
        " The :help command stomps on the Project Window.  Try to avoid that.
        " This is not perfect, but it is alot better than without the mappings.
        " 2018-05-06: (lb): This messes up /-search!
        "   E.g., If you type </> <h> <e>, the autosearch feature does not
        "   activate because Vim is waiting to see if you'll spell h-e-l-p!
        "cnoremap <buffer> help let g:proj_doinghelp = 1<CR>:help

        " 2011-04-14: (lb): dubs_project's <F1> conflicts
        "   with dubs_edit_juice's <F1> find-under-cursor
        " nnoremap <buffer> <F1> :let g:proj_doinghelp = 1<CR><F1>
        "
        " 2021-01-31: (lb): Only match once (first hit) per line.
        " - Only took 10 years to figure this out.
        " - For now, maybe only map from one mode,
        "   so you can access traditional behavior.
        "   - I guess map special behavior only Normal mode, In Insert mode,
        "     maybe you want to jump to all matches (to edit, whatever).
        "   - At least don't map in Visual mode, I mostly only care about
        "     not matching the always-repeated basename, e.g., the 'foo' in
        "       foo=path/to/foo
        " - Thanks, Reddit! (And this is the week after GameStonk, too!):
        "     https://www.reddit.com/r/vim/comments/tvvu6/pattern_to_match_first_occurrence_in_line/
        " - Hints: \{-} is non-greedy, \zs matches start (see also \ze).
        "
        " 2021-02-06: (lb): There's a complementary plugin (or at least another
        " plugin that I like to use, and that I also maintain) that defines its
        " own F1 mapping, which is what we want to adjust here (and why we chose
        " the F1 binding). Though because of how unmap works, even though we only
        " care about the normal mode map, we'll recreate the maps for the other
        " modes that get unwired. See: https://github.com/landonb/dubs_edit_juice.
        silent! unmap <buffer> <F1>
        " Wire a match-once-per-line F1.
        nnoremap <buffer> <F1> /^.\{-}\zs<C-R><C-W><CR>
        " Re-wire the more inclusive dubs_edit_juice bindings.
        inoremap <buffer> <F1> <C-O>/<C-R><C-W><CR>
        vnoremap <buffer> <F1> :<C-U>
          \ <CR>gvy
          \ gV
          \ /<C-R>"<CR>
        " For posterity, here's how you'd make the other modes' bindings
        " more restrictive:
        "   inoremap <buffer> <F1> <C-O>/^.\{-}\zs<C-R><C-W><CR>
        "   vnoremap <buffer> <F1> :<C-U>
        "     \ <CR>gvy
        "     \ gV
        "     \ /^.\{-}\zs<C-R>"<CR>

        " Pressing Home or End moves cursor to edge of window without scrolling.
        " - The Home/End maps are generally used when wrapping in ON, not off,
        "   e.g.,
        "     s  <Home>      * <C-O><Esc>g<Home>
        "     n  <Home>      * g<Home>
        "   stop at the edge on the window, not at the end of the line, which
        "   is useful when wrapping is on. But not so much when wrapping is off.
        " - ALTLY:
        "     nnoremap <buffer> <Home> 0
        "     nnoremap <buffer> <End> $
        "     " etc.
        nnoremap <buffer> <Home> <Home>
        inoremap <buffer> <Home> <C-O><Home>
        snoremap <buffer> <Home> <C-O><Esc><Home>
        nnoremap <buffer> <End> <End>
        inoremap <buffer> <End> <C-O><End>
        snoremap <buffer> <End> <C-O><Esc><End>

        " This is to avoid changing the buffer, but it is not fool-proof (full proof?).
        nnoremap <buffer> <silent> <C-^> <Nop>
        "nnoremap <script> <Plug>ProjectOnly
        "  \ :let lzsave=&lz<CR>:set lz<CR><C-W>o:Project<CR>:silent! wincmd p<CR>:let &lz=lzsave<CR>:unlet lzsave<CR>
        "
        " 2020-02-13: (lb): <Ctrl-w>o not working very well for me, didn't
        " close all my windows; and on restore, hung (no files loaded) until
        " I hit Ctrl-c. So disabling.
        " - See ZoomWin, which also does window-only and restore, but for
        "   any window.
        "     https://github.com/vim-scripts/ZoomWin
        " - (lb): There's not a compelling reason to make a mapping that works
        "   from any window that makes the project tray fullscreen. Users
        "   shouldn't have to make the project tray window wider very often
        "   and when they do, hitting <Space> from within the tray to make it
        "   wider works very well, and it's easy to remember -- it's also what
        "   I've been doing ever since I first installed this plugin. In fact,
        "   I didn't realize this map was here -- and somewhat broken -- until
        "   I stumbled upon ZoomWin and was curious to try it out. Only, it
        "   maps to the same <C-w>o keys, so I saw the conflict, then tested
        "   this feature, then wrote this comment, then committed it.
        "   - tl;dr A general purpose tool like ZoomWin works great. It also
        "     decouples the project tray from doing things outside its core.
        if 0
            " s:DoProjectOnly(void) <<<
            "   Make the file window the only one.
            function! s:DoProjectOnly()
                if winbufnr(0) != g:proj_running
                    let lzsave=&lz
                    set lz
                    only
                    Project
                    silent! wincmd p
                    let &lz=lzsave
                    unlet lzsave
                endif
            endfunction
            " >>>
            nnoremap <script> <Plug>ProjectOnly :call <SID>DoProjectOnly()<CR>
            if match(g:proj_flags, '\Cm') != -1
                if !hasmapto('<Plug>ProjectOnly')
                    nmap <silent> <unique> <C-W>o <Plug>ProjectOnly
                    nmap <silent> <unique> <C-W><C-O> <C-W>o
                endif
            endif
        endif

        " BWARE: Is this a security concern? (Also a feature I've never used.)
        if filereadable(glob('~/.vimproject_mappings')) | source ~/.vimproject_mappings | endif
    endfunction ">>>
    " Autocommands "<<<
    function! s:CreateAutocmds_ProjectBuffer()
        " Autocommands to clean up if we do a buffer wipe
        " These don't work unless we substitute \ for / for Windows
        let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
        exec 'au BufWipeout '.bufname.' unlet g:proj_running'
        exec 'au BufWipeout '.bufname.' silent! nunmap <C-W>o'
        exec 'au BufWipeout '.bufname.' silent! nunmap <C-W><C-O>'
        " This even necessary? Seems unlikely since buffer being wiped...
        exec 'au BufWipeout '.bufname.' au! * '.bufname
        " Autocommands to keep the window the specified size
        exec 'au WinLeave '.bufname.' call s:DoEnsurePlacementSize_au()'
        exec 'au BufEnter '.bufname.' call s:DoSetupAndSplit_au()'
        au WinLeave * call s:RecordPrevBuffer_au()

        return bufname
    endfunction ">>>
    function! s:SetProjRunning(bufname) "<<<
        " Verify that :Project loaded okay
        " [2021-02-06: At least I think that's what's happening here.]
        setlocal buflisted
        let g:proj_running = bufnr(a:bufname.'\>')
        if g:proj_running == -1
            call confirm('Project/Vim error. Please Enter :Project again and report this bug.', "&OK", 1)
            unlet g:proj_running
        endif
        setlocal nobuflisted
    endfunction ">>>

    " *** s:Project() top-level calls (everything above is inline fcn. defs)

    call s:InitializeGlobals()
    let l:filename = s:ResolveVimprojectsPath(a:filename)
    let l:already_open = s:OpenOrFocusProjectWindow(l:filename)
    if l:already_open

        return
    endif
    call s:PrepareReusableCommands()
    call s:SetLocalOptions()
    call s:CreateProjectSyntaxRulesAndHighlights()
    if exists("g:proj_running")

        return
    endif
    call s:CreateMaps_ProjectBuffer()
    let l:bufname = s:CreateAutocmds_ProjectBuffer()
    call s:SetProjRunning(l:bufname)
endfunction ">>>

" :Project and :ToggleProject commands "<<<

" :Project command " <<<
if exists(':Project') != 2
    command -nargs=? -complete=file Project call <SID>Project('<args>')
endif

">>>

" DoToggleProject function and maps "<<<
if !exists("*<SID>DoToggleProject()")
    function! s:DoToggleProject()
        if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
            " :call <SID>Project("~/.vimprojects")
            Project
        else
            let l:proj_mywindow = winnr()
            Project
            hide
            if winnr() != l:proj_mywindow
                wincmd p
            endif
        endif
    endfunction
endif

nnoremap <script> <Plug>ToggleProject :call <SID>DoToggleProject()<CR>

if exists('g:proj_flags') && (match(g:proj_flags, '\Cg') != -1)
    if !hasmapto('<Plug>ToggleProject')
        nmap <silent> <F12> <Plug>ToggleProject
    endif
endif

">>>

" :ToggleProject command "<<<
" [lb] 2010.02.24: Expose externally, too.
command! ToggleProject call <SID>DoToggleProject()
">>>

finish
">>>

