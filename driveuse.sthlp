{smcl}
{* *! version 1.0.0 21may2026 Author: Eric A. Booth}{...}
{vieweralsosee "use" "help use"}{...}
{viewerjumpto "Syntax" "driveuse##syntax"}{...}
{viewerjumpto "Description" "driveuse##description"}{...}
{viewerjumpto "Options" "driveuse##options"}{...}
{viewerjumpto "Author" "driveuse##author"}{...}
{hline}
Help file for {hi:driveuse}
{hline}

{title:Title}

{phang}
{bf:driveuse} {hline 2} Use datasets from Google Drive with cross-platform path handling


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:driveuse} [{it:varlist}] [{cmd:using}] {it:filename} [{it:if}] [{it:in}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clear}}Replace data in memory{p_end}
{synopt:{opt nolabel}}Do not load value labels{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:driveuse} is a wrapper for {help use} that automatically detects the local path to Google Drive
on both macOS and Windows. It allows users to reference files relative to their Texas 2036 shared
drive folder ({cmd:Shared drives/Data and Research Team/}) without hardcoding local absolute paths.

{pstd}
On macOS, it searches for {cmd:Library/CloudStorage/GoogleDrive-*/Shared drives/Data and Research Team}.
On Windows, it defaults to the {cmd:G:/Shared drives/Data and Research Team/} virtual drive.

{pstd}
{cmd:driveuse} also creates two global macros that act as base folder shortcuts:
{break}  {bf:$driveuse} - The path to the shared drive base folder.
{break}  {bf:$sf} - (Short for "Source Files") An alias for the same path.

{pstd}
These globals can be used to construct paths for other Stata commands like {help save}, {help export}, or {help do}.


{marker examples}{...}
{title:Examples}

{phang}1. Basic load from the shared drive base:{p_end}
{pmore}{cmd:. driveuse "mydata.dta", clear}{p_end}

{phang}2. Load from a subdirectory:{p_end}
{pmore}{cmd:. driveuse "ProjectA/data/raw_data.dta", clear}{p_end}

{phang}3. Load specific variables with an if condition:{p_end}
{pmore}{cmd:. driveuse id age using "survey.dta" if region == 1, clear}{p_end}

{phang}4. Use the global shortcuts for other commands:{p_end}
{pmore}{cmd:. driveuse "raw.dta", clear}{p_end}
{pmore}{cmd:. gen newvar = 1}{p_end}
{pmore}{cmd:. save "$sf/processed/clean_data.dta", replace}{p_end}

{phang}5. Run driveuse without arguments just to initialize globals:{p_end}
{pmore}{cmd:. driveuse}{p_end}
{pmore}{cmd:. do "$sf/scripts/analysis.do"}{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt clear} permits the data to be loaded even if there is a dataset already in memory and even if that dataset has changed since it was last saved.

{phang}
{opt nolabel} prevents the loading of value labels.


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}
