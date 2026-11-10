* test_driveuse.do: checks driveuse against the fake folder layouts in
* tests/driveuse_layouts.csv, then loads data through it, then checks this
* computer. It tests the repo copy of the commands, not the published copy,
* and saves its answers for tests/test_driveuse_R.R to compare with R's.
* Run it from the driveuse-stata-public folder:
*     do tests/test_driveuse.do
* TX2036_DRIVE_ROOT must not be set as an environment variable.

version 16
clear all
set more off

local repo `"`c(pwd)'"'
cap confirm file `"`repo'/tests/driveuse_layouts.csv"'
if _rc {
    di as error "Run this file from the driveuse-stata-public folder."
    exit 601
}
local env : env TX2036_DRIVE_ROOT
if `"`env'"' != "" {
    di as error "Unset the TX2036_DRIVE_ROOT environment variable first."
    exit 198
}
macro drop TX2036_DRIVE_ROOT
adopath ++ `"`repo'"'
cap program drop driveuse
cap program drop _driveuse_root
findfile driveuse.ado
assert strpos(`"`r(fn)'"', `"`repo'"') == 1
findfile _driveuse_root.ado
assert strpos(`"`r(fn)'"', `"`repo'"') == 1

* folder helpers: make a folder and its parents; delete a folder tree
cap program drop _t_mkdirp
program define _t_mkdirp
    args d
    local n = length(`"`d'"')
    forvalues i = 2/`n' {
        if substr(`"`d'"', `i', 1) == "/" {
            local sub = substr(`"`d'"', 1, `i' - 1)
            cap mkdir `"`sub'"'
        }
    }
    cap mkdir `"`d'"'
end
cap program drop _t_rmtree
program define _t_rmtree
    args d
    mata: st_local("ok", strofreal(direxists(st_local("d"))))
    if !`ok' exit
    local fs : dir `"`d'"' files "*"
    foreach f of local fs {
        erase `"`d'/`f'"'
    }
    local ds : dir `"`d'"' dirs "*"
    foreach s of local ds {
        _t_rmtree `"`d'/`s'"'
    }
    cap rmdir `"`d'"'
end

local tmp = subinstr(`"`c(tmpdir)'"', "\", "/", .)
if substr(`"`tmp'"', -1, 1) == "/" local tmp = substr(`"`tmp'"', 1, length(`"`tmp'"') - 1)
local base `"`tmp'/driveuse_layouts"'
_t_rmtree `"`base'"'
_t_mkdirp `"`base'"'

* 1. Fake layouts ------------------------------------------------------------
import delimited using `"`repo'/tests/driveuse_layouts.csv"', varnames(1) ///
    stringcols(_all) delimiter(",") bindquote(strict) encoding("utf-8") clear
keep if inlist(scope, "both", "stata")
local N = _N
tempname post
tempfile results
postfile `post' str8 case str8 os str244 expect str244 got str6 result using `"`results'"'
forvalues i = 1/`N' {
    foreach v in case os drive override dirs expect {
        local `v' = `v'[`i']
    }
    local root `"`base'/`case'"'
    local rest `"`dirs'"'
    while `"`rest'"' != "" {
        gettoken d rest : rest, parse(";")
        if `"`d'"' != ";" _t_mkdirp `"`root'/`d'"'
    }
    local opts `"os(`os') home(`"`root'/home"') winroot(`"`root'/win"')"'
    if `"`drive'"' != "" local opts `"`opts' drive(`"`drive'"')"'
    if `"`override'"' != "" local opts `"`opts' override(`"`root'/`override'"')"'
    di _n as text "{hline 4} `case' (`os')"
    cap noi _driveuse_root, `opts'
    local rc = _rc
    local got = cond(`rc', "ERROR", `"`r(path)'"')
    if `rc' & `rc' != 601 local got "rc `rc'"
    if `"`got'"' != "ERROR" & substr(`"`got'"', 1, 3) != "rc " {
        local got = subinstr(`"`got'"', `"`root'/"', "", 1)
    }
    local result = cond(`"`got'"' == `"`expect'"', "pass", "FAIL")
    post `post' ("`case'") ("`os'") (`"`expect'"') (`"`got'"') ("`result'")
}
postclose `post'

* 2. Loading data through TX2036_DRIVE_ROOT ---------------------------------
local fr `"`base'/override/Shared drives"'
_t_mkdirp `"`fr'/Data and Research Team/Project A"'
_t_mkdirp `"`fr'/Other Drive/sub"'
sysuse auto, clear
save `"`fr'/Data and Research Team/Project A/auto.dta"', replace
save `"`fr'/Other Drive/sub/auto.dta"', replace
global TX2036_DRIVE_ROOT `"`fr'"'

driveuse
assert `"`r(method)'"' == "TX2036_DRIVE_ROOT global"
assert `"$sf"' == `"`fr'/Data and Research Team"' & `"$driveuse"' == `"$sf"'

driveuse "Project A/auto.dta", clear
assert _N == 74
assert `"`r(file)'"' == `"`fr'/Data and Research Team/Project A/auto.dta"'
driveuse make price foreign using "Project A/auto.dta" if price > 10000, clear
assert _N == 10 & c(k) == 3
* use's own order; with a varlist, if can name only variables in it
driveuse make price if price > 10000 using "Project A/auto.dta", clear
assert _N == 10 & c(k) == 2
driveuse using "Project A/auto.dta" in 1/5, clear
assert _N == 5
driveuse "Project A/auto.dta" if make == "AMC Concord", clear
assert _N == 1
driveuse "Project A/auto.dta" if inlist(rep78, 1, 2), clear
assert _N == 10
driveuse "Project A/auto.dta", clear nolabel
cap label list origin
assert _rc == 111
driveuse "Project A/auto.dta", clear
label list origin
driveuse `"`fr'/Other Drive/sub/auto.dta"', clear
assert _N == 74

* a $ inside the user's text reaches -use- unexpanded: if driveuse expanded
* $five a second time, the condition would read s == "WRONG" and match nothing
global five "WRONG"
sysuse auto, clear
keep in 1/2
gen s = cond(_n == 1, "\$five", "other")
save `"`fr'/Data and Research Team/Project A/dollar.dta"', replace
driveuse "Project A/dollar.dta" if s == "\$five", clear
assert _N == 1
driveuse make s using "Project A/dollar.dta" if s == "\$five", clear
assert _N == 1 & c(k) == 2
local cond `"if s == "\$five""'
driveuse "Project A/dollar.dta" `macval(cond)', clear
assert _N == 1
macro drop five

* another drive leaves $sf alone
driveuse "sub/auto.dta", drive("Other Drive") clear
assert _N == 74 & `"`r(path)'"' == `"`fr'/Other Drive"'
assert `"$sf"' == `"`fr'/Data and Research Team"'
driveuse, drive("Other Drive")
assert `"`r(path)'"' == `"`fr'/Other Drive"' & `"`r(drive)'"' == "Other Drive"

* failures stop before the globals change
global sf "unchanged"
global driveuse "unchanged"
cap noi driveuse, drive("No Such Drive")
assert _rc == 601
cap noi driveuse Project A/auto.dta, clear
assert _rc == 198
cap noi driveuse make using, clear
assert _rc == 198
assert "$sf" == "unchanged" & "$driveuse" == "unchanged"
cap noi driveuse "Project A/missing.dta", clear
assert _rc == 601
macro drop TX2036_DRIVE_ROOT

* 3. This computer ------------------------------------------------------------
* A computer with no team drive (no @texas2036.org Google Drive account)
* cannot run this step. It is skipped and reported; every other check runs.
macro drop sf driveuse
cap noi driveuse
if _rc == 601 {
    local live "NONE"
    local livehow "skipped: driveuse found no team drive on this computer"
}
else {
    assert _rc == 0
    local live `"`r(path)'"'
    local livehow `"`r(method)' `r(account)'"'
    assert `"$sf"' == `"`live'"' & `"$driveuse"' == `"`live'"'
    mata: st_local("ok", strofreal(direxists(st_local("live"))))
    assert `ok'
    assert substr(`"`live'"', -36, .) == "Shared drives/Data and Research Team"
}

* 4. Report, and save the answers for tests/test_driveuse_R.R ---------------
use `"`results'"', clear
preserve
keep case got
set obs `=_N + 1'
replace case = "LIVE" in l
replace got = `"`live'"' in l
export delimited case got using `"`tmp'/driveuse_results_stata.csv"', replace
restore
list case os result got if result != "pass", noobs abbreviate(8)
count if result != "pass"
local nfail = r(N)
di _n as text "layouts: " as result _N - `nfail' as text " of " as result _N as text " pass"
di as text "this computer: " as result `"`live'"' as text " (`livehow')"
assert `nfail' == 0
_t_rmtree `"`base'"'
if "`live'" == "NONE" di as result "all driveuse tests passed (this computer skipped: no team drive)"
else di as result "all driveuse tests passed"
