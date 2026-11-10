# test_driveuse_R.R: checks driveuse.R against the fake folder layouts in
# tests/driveuse_layouts.csv, finds files through it, and checks this
# computer. When tests/test_driveuse.do has run first, it also compares each
# answer with the Stata command's, case by case. It checks that any other
# copies of driveuse.R you name match this one.
# Run it from the driveuse-stata-public folder:
#   Rscript tests/test_driveuse_R.R [path/to/another/copy/driveuse.R ...]

if (!file.exists(file.path("tests", "driveuse_layouts.csv")))
  stop("Run this file from the driveuse-stata-public folder.")
if (nzchar(Sys.getenv("TX2036_DRIVE_ROOT")))
  stop("Unset the TX2036_DRIVE_ROOT environment variable first.")
source("driveuse.R")
fails <- character(0)
check <- function(ok, what) {
  if (!isTRUE(ok)) fails <<- c(fails, what)
  invisible(ok)
}
err <- function(expr) tryCatch({ force(expr); "" }, error = function(e) conditionMessage(e))

# 1. Copies of driveuse.R ------------------------------------------------------
md5 <- function(f) unname(tools::md5sum(f))
pub <- file.path("..", "driveuse.R")
if (file.exists(pub)) {
  same <- md5(pub) == md5("driveuse.R")
  cat("published copy", normalizePath(pub), ":", if (same) "same" else "differs (codemenu, refresh publishes it)", "\n")
}
for (f in commandArgs(trailingOnly = TRUE)) {
  same <- check(md5(f) == md5("driveuse.R"), paste("copy differs:", f))
  cat("copy", f, ":", if (same) "same" else "DIFFERS", "\n")
}

# 2. Fake layouts --------------------------------------------------------------
cases <- read.csv(file.path("tests", "driveuse_layouts.csv"),
                  colClasses = "character", na.strings = character(0))
cases <- cases[cases$scope %in% c("both", "r"), ]
base <- .du_norm(file.path(tempdir(), "driveuse_layouts"))
unlink(base, recursive = TRUE)
res <- do.call(rbind, lapply(seq_len(nrow(cases)), function(i) {
  k <- cases[i, ]
  root <- file.path(base, k$case)
  for (d in strsplit(k$dirs, ";", fixed = TRUE)[[1]])
    dir.create(file.path(root, d), recursive = TRUE, showWarnings = FALSE)
  got <- tryCatch(driveuse_root(
    drive = if (nzchar(k$drive)) k$drive else "Data and Research Team",
    os = k$os, home = file.path(root, "home"),
    override = if (nzchar(k$override)) file.path(root, k$override) else "",
    winroot = file.path(root, "win"))$path,
    error = function(e) "ERROR")
  if (startsWith(got, paste0(root, "/"))) got <- substring(got, nchar(root) + 2)
  data.frame(case = k$case, expect = k$expect, r = got, note = k$note)
}))
for (i in which(res$r != res$expect)) check(FALSE, paste("layout", res$case[i]))

# 3. Paths through TX2036_DRIVE_ROOT -------------------------------------------
fr <- file.path(base, "override", "Shared drives")
dr <- .du_norm(file.path(fr, "Data and Research Team"))
od <- .du_norm(file.path(fr, "Other Drive"))
for (d in c(file.path(dr, "Project A"), file.path(dr, "Project 100% done"), file.path(od, "sub"))) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  write.csv(mtcars, file.path(d, "cars.csv"))
}
Sys.setenv(TX2036_DRIVE_ROOT = fr)
check(identical(driveuse(), dr), "driveuse() through TX2036_DRIVE_ROOT")
check(identical(driveuse("Project A/cars.csv"), file.path(dr, "Project A", "cars.csv")), "path as one string")
check(identical(driveuse("Project A", "cars.csv"), file.path(dr, "Project A", "cars.csv")), "path in parts")
check(nrow(read.csv(driveuse("Project A/cars.csv"))) == 32, "read a file through driveuse()")
check(identical(driveuse("sub/cars.csv", drive = "Other Drive"), file.path(od, "sub", "cars.csv")), "another drive")
check(identical(driveuse(drive = "Other Drive"), od), "another drive's root")
check(identical(driveuse("Project 100% done/cars.csv"), file.path(dr, "Project 100% done", "cars.csv")), "a % in the path")
check(identical(driveuse(file.path(od, "sub", "cars.csv")), file.path(od, "sub", "cars.csv")), "absolute path")
check(grepl("does not exist", err(driveuse("Project A/missing.csv"))), "a missing file stops")
check(grepl("drive = \"Other Drive\"", err(driveuse("Other Drive", "sub")), fixed = TRUE),
      "an old-style call stops and names drive =")
check(grepl("does not contain", err(driveuse(drive = "No Such Drive"))), "a missing drive stops")
msg <- ""
invisible(withCallingHandlers(driveuse(quiet = FALSE), message = function(m) {
  msg <<- conditionMessage(m)
  invokeRestart("muffleMessage")
}))
check(grepl("TX2036_DRIVE_ROOT", msg), "quiet = FALSE names the source")
Sys.unsetenv("TX2036_DRIVE_ROOT")

# 4. This computer -------------------------------------------------------------
live <- tryCatch(driveuse(), error = function(e) paste("ERROR:", conditionMessage(e)))
check(dir.exists(live) && endsWith(live, "Shared drives/Data and Research Team"), "this computer")

# 5. Side by side with the Stata command ----------------------------------------
sfile <- file.path(dirname(tempdir()), "driveuse_results_stata.csv")
if (file.exists(sfile)) {
  st <- read.csv(sfile, colClasses = "character", na.strings = character(0))
  res$stata <- st$got[match(res$case, st$case)]
  cat("\nLayouts: S = Stata, R = R; pass means the answer equals the expected path\n")
  for (i in seq_len(nrow(res))) {
    s_ok <- identical(res$stata[i], res$expect[i])
    r_ok <- identical(res$r[i], res$expect[i])
    check(s_ok, paste("Stata layout", res$case[i]))
    cat(sprintf("  %-4s S %-4s R %-4s %s\n", res$case[i], if (s_ok) "pass" else "FAIL",
                if (r_ok) "pass" else "FAIL", res$note[i]))
  }
  slive <- st$got[st$case == "LIVE"]
  check(identical(slive, live), "Stata and R find the same folder on this computer")
  cat("this computer: Stata and R", if (identical(slive, live)) "agree" else "DISAGREE", "\n")
} else {
  cat("\nRun tests/test_driveuse.do first to compare with Stata.\n")
  for (i in seq_len(nrow(res)))
    cat(sprintf("  %-4s R %-4s %s\n", res$case[i], if (res$r[i] == res$expect[i]) "pass" else "FAIL", res$note[i]))
}
cat("this computer:", live, "\n")
unlink(base, recursive = TRUE)

if (length(fails)) {
  cat("\nFAILED:\n  ", paste(fails, collapse = "\n  "), "\n", sep = "")
  quit(status = 1)
}
cat(sprintf("\nall driveuse.R tests passed (%d layouts)\n", nrow(res)))
