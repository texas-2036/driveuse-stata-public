# How driveuse finds a shared drive

The Stata command (`driveuse.ado` with its helper `_driveuse_root.ado`) and the
R version (`driveuse.R`) follow these rules. `tests/driveuse_layouts.csv`
lists fake folder layouts and the path each version should return.

## Rules

1. **Override.** When `TX2036_DRIVE_ROOT` is set, it names the folder that
   contains the shared drives, such as `G:/Shared drives`. driveuse uses
   `<that folder>/<drive>` if it exists and stops with an error if it does
   not. Stata reads a global of that name before the environment variable,
   because Stata opened from the Mac Dock does not see variables set in a
   shell profile. R reads the environment variable, which `.Renviron` can set.
2. **Mac.** driveuse lists the `GoogleDrive-*` folders in
   `<home>/Library/CloudStorage`, where `<home>` is the `HOME` environment
   variable (or `/Users/<username>` if `HOME` is empty). It sorts them by byte
   value, keeps those whose names end in `@texas2036.org` (in any case), and
   uses the first one that contains `Shared drives/<drive>`. It never uses a
   folder that belongs to another account.
3. **Windows.** driveuse uses `G:/Shared drives/<drive>`, the letter Google
   Drive for desktop uses by default. It checks no other letters.
4. **Other systems, such as Linux.** driveuse uses only the override.
5. **Existence first.** driveuse confirms that the folder exists before it
   sets a global or returns a path. When it finds nothing, it stops and says
   what it tried.
6. **Drive name.** The default is `Data and Research Team`, and any other
   shared drive can be named. In Stata, `$sf` and `$driveuse` always store the
   Data and Research Team path.
7. **Paths in R.** `driveuse("ProjectA/x.csv")` returns a path inside the
   drive and stops if it does not exist; `driveuse(..., drive = "Other Drive")`
   works in another drive. The Stata equivalents are
   `driveuse "ProjectA/x.dta"` and `driveuse "x.dta", drive("Other Drive")`.

When Google Drive is somewhere these rules do not look, such as another
Windows drive letter, `_codeshare/1_Install_TX2036.do` records the folder as
`TX2036_DRIVE_ROOT` in the person's `sysprofile.do`, so the override rule
covers it. `help driveuse` describes the installer.

## Tests

- **Stata:** from this folder, run `do tests/test_driveuse.do`. It builds each
  layout under `c(tmpdir)`, checks `_driveuse_root` against it, loads data
  through `driveuse` (including conditions that contain `$`), checks this
  computer, and saves its answers for the R test.
- **R:** then run `Rscript tests/test_driveuse_R.R [other copies of driveuse.R]`.
  It runs the same layouts, compares each answer with Stata's, and checks that
  the named copies of driveuse.R match this one.

In `driveuse_layouts.csv`, paths are relative to each case's folder. `dirs`
lists the folders that exist, separated by semicolons. `expect` is the path
driveuse should return, or `ERROR`.

On 2026-10-14 (Stata 19.5 and R 4.6.0 on a Mac), both versions returned the
expected path for all 23 layouts and found the same folder on that computer.

## Choices made to keep it simple

- **No search of other Windows drive letters or of the registry.** Google
  documents a `DefaultMountPoint` registry value, but not whether the app
  writes it when a user picks another letter
  ([Advanced Drive for desktop configuration](https://knowledge.workspace.google.com/admin/drive/advanced-drive-for-desktop-configuration),
  retrieved 2026-10-14), and reading it from Stata needs a shell call. The
  installer records the folder instead.
- **No `/Volumes/GoogleDrive` check.** Google Drive for desktop moved to
  `Library/CloudStorage` in 2022.
- **No `~` expansion.** Paths use `HOME` or full paths, because `~` does not
  expand the same way on every computer.

## To confirm on a Windows computer

- Google Drive for desktop on `G:`: driveuse finds the drive.
- Google Drive on another letter: after the installer runs with that letter,
  driveuse finds the drive through `TX2036_DRIVE_ROOT`.
