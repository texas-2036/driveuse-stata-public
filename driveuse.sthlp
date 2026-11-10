{smcl}
{* *! version 2.0.1 10nov2026 Author: Eric A. Booth}{...}
{vieweralsosee "use" "help use"}{...}
{viewerjumpto "Syntax" "driveuse##syntax"}{...}
{viewerjumpto "Description" "driveuse##description"}{...}
{viewerjumpto "Options" "driveuse##options"}{...}
{viewerjumpto "Installing on a new computer" "driveuse##install"}{...}
{viewerjumpto "Unusual setups" "driveuse##override"}{...}
{viewerjumpto "Calling driveuse from your own programs" "driveuse##programs"}{...}
{viewerjumpto "R version" "driveuse##r"}{...}
{viewerjumpto "Examples" "driveuse##examples"}{...}
{viewerjumpto "Stored results" "driveuse##results"}{...}
{viewerjumpto "Author" "driveuse##author"}{...}
{hline}
Help file for {hi:driveuse}
{hline}

{title:Title}

{phang}
{bf:driveuse} {hline 2} Use datasets from Google Drive with cross-platform path handling


{marker syntax}{...}
{title:Syntax}

{pstd}
Load a dataset from a shared drive:

{phang2}
{cmd:driveuse} [{it:varlist}] [{cmd:using}] {it:filename} [{it:if}] [{it:in}]
[{cmd:,} {opt clear} {opt nolabel} {opt d:rive(name)}]

{pstd}
Find a shared drive and set the global shortcuts:

{phang2}
{cmd:driveuse} [{cmd:,} {opt d:rive(name)}]

{pstd}
{it:filename} is a path inside the shared drive, such as
{cmd:"ProjectA/data/raw.dta"}. Put a filename that contains spaces in double
quotes. A full path, such as {cmd:"/Users/me/x.dta"} or {cmd:"C:/data/x.dta"},
is used as typed.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clear}}replace the data in memory{p_end}
{synopt:{opt nolabel}}do not load value labels{p_end}
{synopt:{opt d:rive(name)}}use another shared drive; default is {cmd:Data and Research Team}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:driveuse} finds the Texas 2036 {cmd:Data and Research Team} shared drive on
this computer and sets the globals {cmd:$sf} and {cmd:$driveuse} to its path.
Given a filename, it then loads that dataset with {help use}. Because each
computer finds its own path, the same do-file runs on every team member's Mac
or Windows computer.

{pstd}
{cmd:driveuse} looks in these places, in order:

{p 8 12 2}
1. The folder named by {cmd:TX2036_DRIVE_ROOT}, when it is set (see
{help driveuse##override:Unusual setups}). {cmd:driveuse} then looks nowhere
else.{p_end}
{p 8 12 2}
2. On a Mac, the Google Drive for desktop folder of your Texas 2036 account:
{cmd:/Users/}{it:you}{cmd:/Library/CloudStorage/GoogleDrive-}{it:you}{cmd:@texas2036.org/Shared drives}.
It uses only account folders whose names end in {cmd:@texas2036.org}, so a
personal Google account on the same Mac is never used.{p_end}
{p 8 12 2}
3. On Windows, {cmd:G:/Shared drives}, the drive letter Google Drive for desktop
uses unless someone changes it.{p_end}

{pstd}
Before it sets anything, {cmd:driveuse} confirms that the shared drive's folder
exists. When it cannot find the drive, it stops with error 601 and says what it
tried.

{pstd}
{cmd:$sf} and {cmd:$driveuse} store the same path, with no trailing slash, so you
can write {cmd:"$sf/ProjectA/output.dta"} in {help save}, {help export}, or
{help do}. The team setup also sets them each time Stata starts.


{marker options}{...}
{title:Options}

{phang}
{opt clear} loads the data even if the data in memory have changed since they
were last saved.

{phang}
{opt nolabel} loads the data without their value labels.

{phang}
{opt drive(name)} names another shared drive, such as
{cmd:drive("Other Drive")}. {it:filename} is then a path inside that drive, and
{cmd:r(path)} returns the drive's path. {cmd:$sf} and {cmd:$driveuse} always
point to the Data and Research Team drive, so this option leaves them
unchanged.


{marker install}{...}
{title:Installing on a new computer}

{pstd}
The team setup makes {cmd:driveuse} and the other {cmd:_codeshare} commands
available each time Stata starts. To set it up on a new computer, install
Google Drive for desktop and sign in with your {cmd:@texas2036.org} account.
Then copy the block for your computer into a new do-file and run it. The block
runs the team installer, {cmd:_codeshare/1_Install_TX2036.do}, and checks the
setup. You do not need to restart Stata.

{pstd}
{bf:Mac}

{p 8 8 2}{cmd:* Texas 2036 Stata setup on a Mac}{p_end}
{p 8 8 2}{cmd:* 1. Find your @texas2036.org Google Drive folder. If a line}{p_end}
{p 8 8 2}{cmd:* below stops with "not found", install Google Drive for}{p_end}
{p 8 8 2}{cmd:* desktop and sign in with your @texas2036.org account.}{p_end}
{p 8 8 2}{cmd:local home : env HOME}{p_end}
{p 8 8 2}{cmd:local base "`home'/Library/CloudStorage"}{p_end}
{p 8 8 2}{cmd:local acct : dir "`base'" dirs "GoogleDrive-*@texas2036.org"}{p_end}
{p 8 8 2}{cmd:local acct : word 1 of `acct'}{p_end}
{p 8 8 2}{cmd:local cs "`base'/`acct'/Shared drives"}{p_end}
{p 8 8 2}{cmd:local cs "`cs'/Data and Research Team/_codeshare"}{p_end}
{p 8 8 2}{cmd:confirm file "`cs'/1_Install_TX2036.do"}{p_end}
{p 8 8 2}{cmd:* 2. Run the team installer, then check the setup}{p_end}
{p 8 8 2}{cmd:do "`cs'/1_Install_TX2036.do" "`cs'"}{p_end}
{p 8 8 2}{cmd:which driveuse}{p_end}
{p 8 8 2}{cmd:driveuse}{p_end}
{p 8 8 2}{cmd:display "$datashare"}{p_end}

{pstd}
{bf:Windows}

{p 8 8 2}{cmd:* Texas 2036 Stata setup on Windows}{p_end}
{p 8 8 2}{cmd:* 1. Find the shared drive. If Google Drive uses a letter other}{p_end}
{p 8 8 2}{cmd:* than G:, change G: on the next line. If the confirm line}{p_end}
{p 8 8 2}{cmd:* stops with "not found", start Google Drive for desktop and}{p_end}
{p 8 8 2}{cmd:* sign in with your @texas2036.org account.}{p_end}
{p 8 8 2}{cmd:local cs "G:/Shared drives/Data and Research Team/_codeshare"}{p_end}
{p 8 8 2}{cmd:confirm file "`cs'/1_Install_TX2036.do"}{p_end}
{p 8 8 2}{cmd:* 2. Run the team installer, then check the setup}{p_end}
{p 8 8 2}{cmd:do "`cs'/1_Install_TX2036.do" "`cs'"}{p_end}
{p 8 8 2}{cmd:which driveuse}{p_end}
{p 8 8 2}{cmd:driveuse}{p_end}
{p 8 8 2}{cmd:display "$datashare"}{p_end}

{pstd}
{bf:What the installer does.} It writes a short {cmd:sysprofile.do} into your
PERSONAL ado folder ({cmd:c(sysdir_personal)}). Stata runs that file at every
start, before your own {cmd:profile.do}. The file runs
{cmd:_codeshare/tx2036_startup.do}, which adds the {cmd:_codeshare} commands and
sets {cmd:$sf}, {cmd:$driveuse}, {cmd:$codeshare}, and {cmd:$datashare}. When
Google Drive is somewhere {cmd:driveuse} does not look by itself, such as
another drive letter, the installer also records that folder in
{cmd:sysprofile.do} as {cmd:TX2036_DRIVE_ROOT}, so {cmd:driveuse} finds it in
every session. Last, the installer installs the SSC commands that team code
uses.

{pstd}
{bf:Your profile.do stays yours.} The installer never changes it. Keep your own
settings there; Stata runs them after the team setup, so they win wherever the
two set the same thing. If your {cmd:profile.do} came from the older team setup,
it still has a {cmd:sysdir set SITE} line for {cmd:_codeshare}. Those lines now
run a second time; they do no harm, and the installer points them out so you
can delete them. If you already have a {cmd:sysprofile.do} that the installer
did not write, the installer stops and shows the lines to add to it.

{pstd}
Run the installer again after Google Drive moves to another folder or drive
letter, or after you reinstall Stata.


{marker override}{...}
{title:Unusual setups}

{pstd}
{cmd:TX2036_DRIVE_ROOT} names the folder that contains your shared drives, such
as {cmd:H:/Shared drives}. When it is set, {cmd:driveuse} looks only there. The
installer sets it for you when it needs to, so most people never set it by
hand. To set it yourself, use a Stata global or an environment variable; the
global takes precedence.

{phang2}
As a Stata global, in your {cmd:profile.do} or at the top of a do-file:{p_end}
{phang3}
{cmd:. global TX2036_DRIVE_ROOT "H:/Shared drives"}{p_end}

{phang2}
As an environment variable, which R also reads. On Windows, run this in a
Command Prompt and then restart Stata:{p_end}
{phang3}
{cmd:setx TX2036_DRIVE_ROOT "H:\Shared drives"}{p_end}
{pmore2}
On a Mac, Stata opened from the Dock or Finder does not see variables set in
your shell profile, so use the global instead.{p_end}


{marker programs}{...}
{title:Calling driveuse from your own programs}

{pstd}
{cmd:driveuse} passes a {cmd:$} or {cmd:`} in a filename or {it:if} condition
through to {help use} as typed. A program that wraps {cmd:driveuse} should do
the same, by passing its arguments with {cmd:macval()}; otherwise Stata expands
them a second time before {cmd:driveuse} sees them. For example:

{phang2}{cmd:program define myload}{p_end}
{phang2}{cmd:    syntax anything(everything) [, *]}{p_end}
{phang2}{cmd:    driveuse `macval(anything)', `options'}{p_end}
{phang2}{cmd:end}{p_end}


{marker r}{...}
{title:R version}

{pstd}
{cmd:_codeshare/driveuse.R} follows the same rules and returns paths; it loads
nothing. Source it by its full path, then build paths from it:

{phang2}{cmd:source("G:/Shared drives/Data and Research Team/_codeshare/driveuse.R")}{p_end}
{phang2}{cmd:sf <- driveuse()}{p_end}
{phang2}{cmd:raw <- read.csv(driveuse("ProjectA/data/raw.csv"))}{p_end}
{phang2}{cmd:p <- driveuse("Project", drive = "Other Drive")}{p_end}
{phang2}{cmd:out <- file.path(driveuse(), "ProjectA", "new.csv")}{p_end}

{pstd}
On a Mac, the first line starts with
{cmd:/Users/}{it:you}{cmd:/Library/CloudStorage/GoogleDrive-}{it:you}{cmd:@texas2036.org/Shared drives}.
{cmd:driveuse()} stops when the path does not exist, so build paths for new files
with {cmd:file.path(driveuse(), ...)}. In R, set {cmd:TX2036_DRIVE_ROOT} in the
{cmd:.Renviron} file in your home folder.


{marker examples}{...}
{title:Examples}

{phang}1. Set {cmd:$sf} and {cmd:$driveuse} and see where the drive is:{p_end}
{pmore}{cmd:. driveuse}{p_end}

{phang}2. Load a dataset by its path inside the shared drive:{p_end}
{pmore}{cmd:. driveuse "ProjectA/data/raw_data.dta", clear}{p_end}

{phang}3. Load some variables and observations. As with {help use}, an {it:if}
condition can name only variables in the {it:varlist}:{p_end}
{pmore}{cmd:. driveuse id age region using "ProjectA/survey.dta" if region == 1, clear}{p_end}
{pmore}{cmd:. driveuse using "ProjectA/survey.dta" in 1/100, clear}{p_end}

{phang}4. Use the globals with other commands:{p_end}
{pmore}{cmd:. save "$sf/ProjectA/processed/clean_data.dta", replace}{p_end}
{pmore}{cmd:. do "$sf/ProjectA/scripts/analysis.do"}{p_end}

{phang}5. Work in another shared drive:{p_end}
{pmore}{cmd:. driveuse "Project/file.dta", drive("Other Drive") clear}{p_end}
{pmore}{cmd:. driveuse, drive("Other Drive")}{p_end}
{pmore}{cmd:. global other "`r(path)'"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:driveuse} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(path)}}path of the shared drive{p_end}
{synopt:{cmd:r(drive)}}name of the shared drive{p_end}
{synopt:{cmd:r(method)}}where {cmd:driveuse} found it{p_end}
{synopt:{cmd:r(account)}}Google account, on a Mac{p_end}
{synopt:{cmd:r(file)}}full path of the dataset loaded{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}
