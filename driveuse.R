# =============================================================================
# driveuse.R -- R version of the Stata command driveuse (Texas 2036)
# Version 2.0 (2026-10-14)
#
# Finds a Google Drive shared drive on this computer and returns a path in
# it, so the same script runs on every team member's Mac and Windows
# computer. The Stata command follows the same rules; SPEC.md lists them.
#
#   source("<path>/_codeshare/driveuse.R")
#   sf  <- driveuse()                                 # Data and Research Team
#   f   <- driveuse("ProjectA/data/raw.csv")          # an existing file in it
#   p   <- driveuse("Project", drive = "Other Drive") # a folder in another drive
#   out <- file.path(driveuse(), "ProjectA", "new.csv")   # a file you will make
#
# driveuse() stops when the path does not exist, so build paths for new
# files with file.path(driveuse(), ...). It returns a path and loads nothing;
# read the file with read.csv(), haven::read_dta(), or another reader.
#
# Where it looks, in order:
#   1. TX2036_DRIVE_ROOT, if set: the folder that contains the shared drives,
#      such as G:/Shared drives. driveuse then looks nowhere else. To set it
#      for every R session, add a line like this to the .Renviron file in
#      your home folder:
#      TX2036_DRIVE_ROOT="H:/Shared drives"
#   2. macOS: the GoogleDrive-*@texas2036.org folders in
#      <home>/Library/CloudStorage. Folders of other Google accounts are
#      never used.
#   3. Windows: G:, where Google Drive for desktop puts the drive by default.
#   4. Other systems: only TX2036_DRIVE_ROOT.
#
# The canonical copy is in _codeshare/driveuse-stata-public; codemenu,
# refresh publishes it to _codeshare. Another project keeps a copy in its
# own folder so its scripts can load it before they know where its drive
# is; tests/test_driveuse_R.R checks that copies match.
# =============================================================================

driveuse <- function(..., drive = "Data and Research Team", quiet = TRUE) {
  root <- driveuse_root(drive)
  parts <- c(...)
  if (!quiet) {
    how <- if (nzchar(root$account)) paste("Google Drive account", root$account) else root$method
    message("driveuse: ", drive, " is at ", root$path, " (", how, ")")
  }
  if (!length(parts)) return(root$path)
  if (!is.character(parts)) stop("driveuse: give the path as character strings", call. = FALSE)

  # a full path is used as typed; anything else is a path inside the drive
  full <- if (grepl("^(/|\\\\|[A-Za-z]:)", parts[1])) parts else c(root$path, parts)
  path <- .du_norm(do.call(file.path, as.list(full)))
  if (!file.exists(path)) {
    msg <- paste0("driveuse: ", path, " does not exist.\n",
                  "  To build a path for a new file, use file.path(driveuse(), ...).")
    # an old-style call such as driveuse("Other Drive", "Project") lands here
    if (dir.exists(file.path(dirname(root$path), parts[1]))) {
      msg <- paste0(msg, "\n  \"", parts[1], "\" is a shared drive. driveuse() takes the path first",
                    "\n  and the drive second: driveuse(..., drive = \"", parts[1], "\").")
    }
    stop(msg, call. = FALSE)
  }
  path
}

# Finds the shared drive and returns list(path, method, account).
# driveuse() passes only drive. The other arguments stand in for parts of the
# computer, so tests/test_driveuse_R.R can check fake folder layouts.
driveuse_root <- function(drive = "Data and Research Team", os = NULL, home = NULL,
                          override = NULL, winroot = NULL) {
  suffix <- "@texas2036.org"
  tail <- file.path("Shared drives", drive)
  if (is.null(os)) {
    sys <- Sys.info()[["sysname"]]
    os <- if (sys == "Darwin") "mac" else if (sys == "Windows") "windows" else "other"
  }
  found <- function(path, method, account = "") list(path = path, method = method, account = account)

  # 1. Override: use it if set, and stop if the drive is not there
  if (is.null(override)) override <- Sys.getenv("TX2036_DRIVE_ROOT", "")
  override <- trimws(override)
  if (nzchar(override)) {
    p <- .du_norm(file.path(override, drive))
    if (!dir.exists(p)) {
      stop("driveuse: TX2036_DRIVE_ROOT names a folder that does not contain \"", drive, "\".",
           "\n  Path tried:\n    ", p,
           "\n  TX2036_DRIVE_ROOT should name the folder that contains your shared",
           "\n  drives, such as G:/Shared drives or",
           "\n  /Users/you/Library/CloudStorage/GoogleDrive-you@texas2036.org/Shared drives.",
           call. = FALSE)
    }
    return(found(p, "TX2036_DRIVE_ROOT"))
  }

  # 2. macOS: the first @texas2036.org account folder that has the drive
  if (os == "mac") {
    if (is.null(home)) home <- Sys.getenv("HOME", "")
    if (!nzchar(home)) home <- file.path("/Users", Sys.info()[["user"]])
    base <- .du_norm(file.path(home, "Library", "CloudStorage"))
    accts <- if (dir.exists(base)) basename(list.dirs(base, recursive = FALSE)) else character(0)
    accts <- sort(accts[startsWith(accts, "GoogleDrive-")], method = "radix")  # byte order, as Stata
    ours <- accts[endsWith(tolower(accts), suffix)]
    tried <- character(0)
    for (a in ours) {
      p <- .du_norm(file.path(base, a, tail))
      tried <- c(tried, p)
      if (dir.exists(p)) return(found(p, "Google Drive account folder", substring(a, 13)))
    }
    msg <- if (!length(accts)) {
      paste0("no Google Drive account folder in ", base, ".",
             "\n  Is Google Drive for desktop installed, running, and signed in?")
    } else if (!length(ours)) {
      paste0("no Google Drive account folder ends in ", suffix, ".",
             "\n  Account folders in ", base, ":\n    ", paste(accts, collapse = "\n    "),
             "\n  Sign in to Google Drive for desktop with your ", suffix, " account.")
    } else {
      paste0("shared drive \"", drive, "\" not found.",
             "\n  Check the name and your access to it, or wait for Google Drive to start.")
    }
    .du_fail(msg, tried)
  }

  # 3. Windows: G:, where Google Drive for desktop puts the drive by default
  if (os == "windows") {
    g <- if (is.null(winroot)) "G:" else file.path(winroot, "G")
    p <- .du_norm(file.path(g, tail))
    if (dir.exists(p)) return(found(p, "G: drive"))
    .du_fail(paste0("shared drive \"", drive, "\" not found on G:.",
                    "\n  Is Google Drive for desktop running and signed in with your",
                    "\n  ", suffix, " account? If it uses another drive letter, set",
                    "\n  TX2036_DRIVE_ROOT (see the top of driveuse.R)."), p)
  }

  # 4. Anything else (Linux): only the override
  stop("driveuse: the automatic search covers macOS and Windows only.",
       "\n  Set TX2036_DRIVE_ROOT to the folder that contains your shared drives.",
       call. = FALSE)
}

# forward slashes, no doubled slashes (except a leading //server), no trailing /
.du_norm <- function(p) {
  p <- gsub("\\", "/", p, fixed = TRUE)
  lead <- if (startsWith(p, "//")) "/" else ""
  while (grepl("//", p, fixed = TRUE)) p <- gsub("//", "/", p, fixed = TRUE)
  p <- paste0(lead, p)
  while (nchar(p) > 1 && endsWith(p, "/") && !grepl("^[A-Za-z]:/$", p)) {
    p <- substr(p, 1, nchar(p) - 1)
  }
  p
}

.du_fail <- function(msg, tried) {
  if (length(tried)) msg <- paste0(msg, "\n  Paths tried:\n    ", paste(tried, collapse = "\n    "))
  stop("driveuse: ", msg,
       "\n  For an unusual setup, set TX2036_DRIVE_ROOT to the folder that contains",
       "\n  your shared drives; see the top of driveuse.R.", call. = FALSE)
}
