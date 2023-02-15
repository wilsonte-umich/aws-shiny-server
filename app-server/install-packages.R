# install all R packages required by the app

# initialize
env <- as.list(Sys.getenv())
.libPaths(env$PACKAGE_DIR)

# enumerate common required packages, including the large shiny package and its dependencies
commonPackages <- c(
    "shiny", # obvious
    "yaml"   # required to load the app library list
)

# install missing common packages
getRPackages <- function(lib) {
    if(is.null(lib)) character() 
    else list.dirs(lib, full.names = FALSE, recursive = FALSE)
}
installMissingPackages <- function(packages){
    existingPackages <- unique(unlist(sapply(.libPaths(), getRPackages)))
    newPackages <- packages[!(packages %in% existingPackages)]
    if(length(newPackages) == 0) return()
    install.packages(
        newPackages, 
        lib = env$PACKAGE_DIR, 
        repos = "https://cloud.r-project.org/",
        Ncpus = as.integer(env$N_CPU)
    )
}
installMissingPackages(commonPackages)

# discover and install app packages
appDir <- if(is.null(env$APP_GITHUB_REPO) || env$APP_GITHUB_REPO == "") {
    list.dirs(path = env$APP_DIR, full.names = TRUE, recursive = FALSE)[1] # default to the only expected app subdir
} else {
    repo <- gsub(".git", "", basename(env$APP_GITHUB_REPO))
    file.path(env$APP_DIR, repo)
}
if(is.na(appDir) || !dir.exists(appDir)){
    message("missing app directory, aborting with nothing to do")
    q('no')
}
appPackagesFile <- file.path(appDir, "install-packages.yml")
if(!file.exists(appPackagesFile)){
    message("missing app install-packages.yml file, aborting with nothing to do")
    q('no')
}
appPackages <- unique(unlist(yaml::read_yaml(appPackagesFile)))
installMissingPackages(appPackages)
