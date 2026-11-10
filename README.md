# driveuse

`driveuse` finds the Texas 2036 Data and Research Team shared drive in Google
Drive for desktop, on a Mac or Windows computer, and loads datasets from it.
The same do-file then runs on every team member's computer without edits to
its paths. `driveuse.R` does the same for R scripts.

## Stata

```stata
driveuse                                         // sets $sf and $driveuse
driveuse "ProjectA/data/raw.dta", clear          // a path inside the drive
driveuse id age using "ProjectA/survey.dta" if age > 30, clear
driveuse "Project/file.dta", drive("Other Drive") clear
save "$sf/ProjectA/output.dta", replace
```

`help driveuse` covers the options, where driveuse looks, the team installer
(`_codeshare/1_Install_TX2036.do`), and the `TX2036_DRIVE_ROOT` override for
unusual setups.

## R

```r
source("G:/Shared drives/Data and Research Team/_codeshare/driveuse.R")
sf  <- driveuse()
raw <- read.csv(driveuse("ProjectA/data/raw.csv"))
out <- file.path(driveuse(), "ProjectA", "new.csv")
```

## Files

- `driveuse.ado`, `_driveuse_root.ado`, `driveuse.sthlp`: the Stata command
- `driveuse.R`: the R version
- `SPEC.md`: the rules both versions follow
- `tests/`: fake folder layouts and the Stata and R tests that check them

In the team's `_codeshare` folder, `codemenu, refresh` publishes these files
to the folder Stata searches.

## Author

Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com).
