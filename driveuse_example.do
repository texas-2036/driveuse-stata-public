
**Google drive use
if "`c(os)'" == "MacOSX" {
    local home "/Users/`c(username)'"
    local gd_base "`home'/Library/CloudStorage"

    local gd_folders : dir "`gd_base'" dirs "GoogleDrive-*"
    local gd_folder  : word 1 of `gd_folders'
    local gd_folder  = subinstr(`"`gd_folder'"', `"""', "", .)

    local sf "`gd_base'/`gd_folder'/Shared drives/Data and Research Team"
}
else if "`c(os)'" == "Windows" {
    * Google Drive for Desktop mounts as a virtual drive, default is G:
    * Adjust the drive letter below if yours differs
    local sf "G:/Shared drives/Data and Research Team"
}
global driveuse `"`sf'"'
global sf `sf'

s

**
use `"${sf}/test.dta"', clear
use `"${driveuse}/_datarepository/test.dta"', clear
**



* Basic load
driveuse "test.dta", clear
driveuse "test.dta" if rep78 == 2, clear

* With subdirectory
driveuse "project/data/survey.dta", clear

* Load specific variables only
driveuse id age income using "survey.dta", clear

* With if condition
driveuse "survey.dta" if year == 2024, clear
