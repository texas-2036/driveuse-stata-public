# driveuse

`driveuse` is a Stata utility designed to simplify working with shared Google Drive folders across different operating systems. It acts as a wrapper for the standard `use` command but automatically resolves the local path to Google Drive, ensuring your do-files remain portable between macOS and Windows.

## Why use `driveuse`?

Standard Stata commands like `use` or `sysuse` require you to provide a file path. When working in a team on Google Drive, these paths often break because:
1. **MacOS** uses paths like `/Users/username/Library/CloudStorage/GoogleDrive-email@domain.com/Shared drives/...`
2. **Windows** typically mounts Google Drive as a virtual drive letter like `G:/Shared drives/...`

`driveuse` solves this by dynamically detecting the correct base path.

### Key Benefits
- **Cross-Platform Compatibility:** Write one do-file that runs on both Mac and Windows without any `if/else` logic for paths.
- **Dynamic Username Handling:** Automatically detects the macOS username using Stata's `c(username)`, eliminating hardcoded home directory paths.
- **Persistent Global Shortcuts:** Automatically creates `$driveuse` and `$sf` (source files) globals. Once initialized, you can use these shortcuts in `save`, `import`, `export`, or `do` commands.
- **Zero-Config Initialization:** Simply running `driveuse` with no arguments sets up your environment globals for the session.
- **Full `use` Syntax Support:** Supports `varlist`, `using`, `if`, `in`, `clear`, and `nolabel`.

---

## Global Shortcuts

When you run `driveuse`, it creates two global macros:
- `${driveuse}`: The full path to the "Data and Research Team" shared drive.
- `${sf}`: A convenient short alias for "Source Files" pointing to the same location.

These globals allow you to maintain a clean, readable do-file structure:

```stata
* Initialize globals
driveuse

* Load a dataset
driveuse "project_alpha/data/survey.dta", clear

* Use globals for saving or exporting
save "${sf}/project_alpha/outputs/analysis_results.dta", replace
export excel "${driveuse}/reports/summary.xlsx", firstrow(variables) replace
```

---

## Examples

### 1. Simple Data Loading
```stata
driveuse "marketing/campaign_stats.dta", clear
```

### 2. Loading Specific Variables with Conditions
```stata
driveuse user_id timestamp using "logs/activity.dta" if year == 2024, clear
```

### 3. Setting Up Base Folders
If you have a complex project, you can set a dependent path based on the `driveuse` global:
```stata
driveuse
global myproj "${sf}/Client_A/2024_Audit"

use "${myproj}/data/raw.dta", clear
do "${myproj}/scripts/clean_data.do"
```

---

## Installation

```stata
net install driveuse, from("https://raw.githubusercontent.com/ericbooth/driveuse-stata/master/") replace
which driveuse
help driveuse
```

## Author

Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com).
