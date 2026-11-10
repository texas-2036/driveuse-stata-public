*! version 2.0.1  10nov2026  Eric A. Booth, Texas 2036
*! driveuse: find the team's Google Drive shared drive on any Mac or Windows
*! computer, set $sf and $driveuse, and load a dataset from it.
*! _driveuse_root.ado does the search; SPEC.md has the rules.
program define driveuse, rclass
    version 14
    syntax [anything(everything)] [, CLEAR nolabel Drive(string)]

    * 1. Parse [varlist] [using] filename [if] [in]. User text goes through
    *    macval() and never into a one-line if/else, which Stata expands a
    *    second time, so a $ or ` in a filename or condition reaches -use-
    *    as typed
    local pre ""
    local fname ""
    local qual ""
    local usingseen 0
    local wantfile 0
    local inqual 0
    local rest `"`macval(anything)'"'
    while `"`macval(rest)'"' != "" {
        gettoken tok rest : rest, quotes
        if `"`macval(tok)'"' == "using" & !`usingseen' {
            local usingseen 1
            local wantfile 1
        }
        else if `wantfile' {
            local fname `macval(tok)'
            local wantfile 0
        }
        else {
            if inlist(`"`macval(tok)'"', "if", "in") local inqual 1
            if `inqual' {
                local qual `"`macval(qual)' `macval(tok)'"'
            }
            else if `usingseen' {
                di as error `"driveuse: unexpected `macval(tok)' after the filename"'
                exit 198
            }
            else {
                local pre `"`macval(pre)' `macval(tok)'"'
            }
        }
    }
    local vlist ""
    if `usingseen' {
        local vlist `"`macval(pre)'"'
        if `"`macval(fname)'"' == "" {
            di as error "driveuse: filename required after using"
            exit 198
        }
    }
    else if `"`macval(anything)'"' != "" {
        local n : word count `macval(pre)'
        if `n' != 1 {
            di as error "driveuse: specify one filename. Put a filename that contains spaces"
            di as error "  in double quotes, or type driveuse varlist using filename."
            exit 198
        }
        local fname `macval(pre)'
    }

    * 2. Find the shared drive; this stops before anything is set if it fails
    if `"`drive'"' == "" local drive "Data and Research Team"
    _driveuse_root, drive(`"`drive'"')
    local root    `"`r(path)'"'
    local method  `"`r(method)'"'
    local account `"`r(account)'"'
    local team = lower(`"`drive'"') == "data and research team"

    * 3. $sf and $driveuse always mean the Data and Research Team drive
    if `team' {
        global driveuse `"`root'"'
        global sf `"`root'"'
    }

    * 4. No filename: say where the drive is (block ifs keep \$ from expanding)
    if `"`macval(fname)'"' == "" {
        local how `"`method'"'
        if `"`account'"' != "" {
            local how `"Google Drive account `account'"'
        }
        if `team' {
            di as text "driveuse: {bf:\$sf} and {bf:\$driveuse} set to"
        }
        else {
            di as text `"driveuse: `drive' is at"'
        }
        di as result `"  `root'"'
        di as text `"  source: `how'"'
        if !`team' {
            di as text "  stored in r(path); \$sf and \$driveuse are unchanged"
        }
    }

    * 5. Load the file, relative to the drive unless the path is absolute
    else {
        local f `"`macval(fname)'"'
        local c1 = substr(`"`macval(f)'"', 1, 1)
        if inlist(`"`c1'"', "/", "\") | substr(`"`macval(f)'"', 2, 1) == ":" {
            local full `"`macval(f)'"'
        }
        else {
            local full `"`root'/`macval(f)'"'
        }
        if `"`macval(vlist)'"' != "" {
            use `macval(vlist)' using `"`macval(full)'"' `macval(qual)', `clear' `label'
        }
        else {
            use `"`macval(full)'"' `macval(qual)', `clear' `label'
        }
        describe, short
        return local file `"`macval(full)'"'
    }

    return local path    `"`root'"'
    return local drive   `"`drive'"'
    return local method  `"`method'"'
    return local account `"`account'"'
end
