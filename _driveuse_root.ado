*! version 2.0.2  10nov2026  Eric A. Booth, Texas 2036
*! _driveuse_root: find a Google Drive shared drive for -driveuse-.
*!
*! Looks in this order (SPEC.md has the rules; tests/ checks them):
*!   1. TX2036_DRIVE_ROOT, the folder that contains the shared drives
*!      (Stata global first, then the environment variable)
*!   2. macOS: <home>/Library/CloudStorage/GoogleDrive-*@texas2036.org
*!   3. Windows: drive G:, then D: through Z:
*! Returns r(path) r(drive) r(method) r(account), or stops with error 601.
*!
*! driveuse passes only drive(). The other options stand in for parts of the
*! computer, so tests/test_driveuse.do can check fake folder layouts:
*!   os(mac|windows|other) home() override() winroot()

program define _driveuse_root, rclass
    version 14
    syntax [, Drive(string) OS(string) HOME(string) OVERride(string) WINroot(string)]

    local suffix "@texas2036.org"
    if `"`drive'"' == "" local drive "Data and Research Team"
    local tail `"Shared drives/`drive'"'
    if "`os'" == "" {
        if "`c(os)'" == "Windows" local os "windows"
        else if "`c(os)'" == "MacOSX" | strpos("`c(machine_type)'", "Mac") local os "mac"
        else local os "other"
    }
    local os = lower("`os'")
    local path ""
    local method ""
    local account ""
    local tried ""

    * 1. Override: use it if set, and stop if the drive is not there
    local how "TX2036_DRIVE_ROOT"
    if `"`override'"' == "" & `"${TX2036_DRIVE_ROOT}"' != "" {
        local override `"${TX2036_DRIVE_ROOT}"'
        local how "TX2036_DRIVE_ROOT global"
    }
    if `"`override'"' == "" {
        local override : env TX2036_DRIVE_ROOT
        local how "TX2036_DRIVE_ROOT environment variable"
    }
    local override = strtrim(`"`override'"')
    if `"`override'"' != "" {
        _du_norm p `"`override'/`drive'"'
        _du_isdir ok `"`p'"'
        if !`ok' {
            local where ""
            if "`how'" == "TX2036_DRIVE_ROOT global" local where " It is set as a Stata global."
            if "`how'" == "TX2036_DRIVE_ROOT environment variable" {
                local where " It is set as an environment variable."
            }
            di as error "driveuse: TX2036_DRIVE_ROOT names a folder that does not contain"
            di as error `"  "`drive'".`where'"'
            di as error "  Path tried:"
            di as error `"    `p'"'
            di as error "  TX2036_DRIVE_ROOT should name the folder that contains your shared"
            di as error "  drives, such as G:/Shared drives or"
            di as error "  /Users/you/Library/CloudStorage/GoogleDrive-you@texas2036.org/Shared drives."
            exit 601
        }
        local path `"`p'"'
        local method `"`how'"'
    }

    * 2. macOS: the first @texas2036.org account folder that has the drive
    else if "`os'" == "mac" {
        if `"`home'"' == "" local home : env HOME
        if `"`home'"' == "" local home "/Users/`c(username)'"
        _du_norm base `"`home'/Library/CloudStorage"'
        local accts ""
        local ours ""
        _du_isdir ok `"`base'"'
        if `ok' {
            local accts : dir `"`base'"' dirs "GoogleDrive-*"
            local accts : list sort accts
        }
        foreach a of local accts {
            if lower(substr(`"`a'"', -length("`suffix'"), .)) == "`suffix'" {
                local ours `"`ours' `"`a'"'"'
            }
        }
        foreach a of local ours {
            if `"`path'"' == "" {
                local p `"`base'/`a'/`tail'"'
                local tried `"`tried' `"`p'"'"'
                _du_isdir ok `"`p'"'
                if `ok' {
                    local path `"`p'"'
                    local account = substr(`"`a'"', 13, .)
                    local method "Google Drive account folder"
                }
            }
        }
        if `"`path'"' == "" {
            if `"`accts'"' == "" {
                di as error `"driveuse: no Google Drive account folder in `base'."'
                di as error "  Is Google Drive for desktop installed, running, and signed in?"
            }
            else if `"`ours'"' == "" {
                di as error "driveuse: no Google Drive account folder ends in `suffix'."
                di as error `"  Account folders in `base':"'
                foreach a of local accts {
                    di as error `"    `a'"'
                }
                di as error "  Sign in to Google Drive for desktop with your `suffix' account."
            }
            else {
                di as error `"driveuse: shared drive "`drive'" not found."'
                di as error "  Check the name and your access to it, or wait for Google Drive to start."
            }
            _du_fail `"`tried'"'
        }
    }

    * 3. Windows: Google Drive for desktop mounts as a virtual drive, default
    *    G: but a user can pick any letter.  Probe G: first, then every other
    *    letter, so a non-default mount still works.
    else if "`os'" == "windows" {
        * winroot() stands in for the set of drives in the tests: the fake
        * drive G: is the folder <winroot>/G
        local ok 0
        foreach L in G D E F H I J K L M N O P Q R S T U V W X Y Z {
            if `"`winroot'"' != "" _du_norm p `"`winroot'/`L'/`tail'"'
            else                   _du_norm p `"`L':/`tail'"'
            _du_isdir ok `"`p'"'
            if `ok' continue, break
        }
        if !`ok' {
            di as error `"driveuse: shared drive "`drive'" not found on drive G: or on D: through Z:."'
            di as error "  Is Google Drive for desktop running and signed in with your"
            di as error "  `suffix' account?"
            _du_fail ""
        }
        local path `"`p'"'
        local method "mounted drive letter"
    }

    * 4. Anything else (Linux): only the override
    else {
        di as error "driveuse: the automatic search covers macOS and Windows only."
        di as error "  Set TX2036_DRIVE_ROOT to the folder that contains your shared drives;"
        di as error "  see {help driveuse##override:help driveuse}."
        exit 601
    }

    return local path    `"`path'"'
    return local drive   `"`drive'"'
    return local method  `"`method'"'
    return local account `"`account'"'
end

* _du_norm name path: put path in the caller's local `name', with forward
* slashes, no doubled slashes (except a leading //server), and no trailing /
program define _du_norm
    args name p
    local p = subinstr(`"`p'"', "\", "/", .)
    local lead = cond(substr(`"`p'"', 1, 2) == "//", "/", "")
    while strpos(`"`p'"', "//") {
        local p = subinstr(`"`p'"', "//", "/", .)
    }
    local p `"`lead'`p'"'
    while length(`"`p'"') > 1 & substr(`"`p'"', -1, 1) == "/" & !regexm(`"`p'"', "^[A-Za-z]:/$") {
        local p = substr(`"`p'"', 1, length(`"`p'"') - 1)
    }
    c_local `name' `"`p'"'
end

* _du_isdir name path: set the caller's local `name' to 1 if path is a folder
program define _du_isdir
    args name p
    mata: st_local("ok", strofreal(direxists(st_local("p"))))
    c_local `name' `ok'
end

* _du_fail tried: list the paths tried, name the override, stop
program define _du_fail
    args tried
    if `"`tried'"' != "" {
        di as error "  Paths tried:"
        foreach p of local tried {
            di as error `"    `p'"'
        }
    }
    di as error "  For an unusual setup, set TX2036_DRIVE_ROOT to the folder that contains"
    di as error "  your shared drives; see {help driveuse##override:help driveuse}."
    exit 601
end
