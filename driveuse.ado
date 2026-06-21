program define driveuse, rclass
    version 14
    syntax [anything(everything)] [if] [in] [, CLEAR nolabel]

    * 1. Detect OS and set base paths
    if inlist("`c(os)'", "MacOSX", "Unix") {     // Apple-Silicon batch Stata reports "Unix"
        local home "/Users/`c(username)'"
        local gd_base "`home'/Library/CloudStorage"
        local folders : dir "`gd_base'" dirs "GoogleDrive-*"
        local folder  : word 1 of `folders'
        local folder  = subinstr(`"`folder'"', `"""', "", .)
        local sf_path "`gd_base'/`folder'/Shared drives/Data and Research Team"
    }
    else if "`c(os)'" == "Windows" {
        * Google Drive for Desktop mounts as a virtual drive, default G:
        local sf_path "G:/Shared drives/Data and Research Team"
    }
    else {
        di as error "driveuse: unsupported operating system (`c(os)')"
        exit 198
    }

    * 2. Set global shortcuts
    global driveuse `"`sf_path'"'
    global sf `"`sf_path'"'

    * 3. Handle 'driveuse' called without arguments (just to set globals)
    if `"`anything'"' == "" {
        di as text "driveuse: globals {bf:\$driveuse} and {bf:\$sf} set to:"
        di as result `"`sf_path'"'
        exit
    }

    * 4. Parse 'anything' for 'using' syntax or simple filename
    local vlist ""
    local fname ""
    
    if strpos(`"`anything'"', " using ") {
        local vlist = substr(`"`anything'"', 1, strpos(`"`anything'"', " using ") - 1)
        local fname = substr(`"`anything'"', strpos(`"`anything'"', " using ") + 7, .)
    }
    else {
        local fname `"`anything'"'
    }

    * Clean filename (remove quotes if user provided them)
    local fname = subinstr(`"`fname'"', `"""', "", .)
    
    * Prepend base path if not already absolute (simple check)
    if !regexm(`"`fname'"', "^(/|[A-Z]:)") {
        local fullpath `"`sf_path'/`fname'"'
    }
    else {
        local fullpath `"`fname'"'
    }

    * 5. Execute 'use'
    if "`vlist'" != "" {
        use `vlist' using `"`fullpath'"' `if' `in', `clear' `nolabel'
    }
    else {
        use `"`fullpath'"' `if' `in', `clear' `nolabel'
    }
    
    describe, short
end
