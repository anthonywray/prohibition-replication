#########################################################################################################
#  Clear memory
rm(list = ls())

#########################################################################################################
#  Set CRAN Mirror (place where code will be downloaded from)
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://mirrors.dotsrc.org/cran/"
  options(repos = r)
})

#########################################################################################################
# Function to determine whether user is running osx, linux, or something else
get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      os <- "osx"
  } else { ## mystery machine
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}

dir.create("analysis/scripts/libraries/R", showWarnings = FALSE)
dir.create(file.path(paste0("analysis/scripts/libraries/R/",get_os())), showWarnings = FALSE)

lib <- file.path(paste0("analysis/scripts/libraries/R/",get_os()))

#########################################################################################################
#  For this R-Session, change location of R-packages to be custom directory 
renv::restore(library = lib, prompt = FALSE)

#########################################################################################################
#  Set Library paths
.libPaths(lib)
