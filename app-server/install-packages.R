# install all R packages required by the server and apps

# initialize
env <- as.list(Sys.getenv())
.libPaths(env$PACKAGE_DIR)

# enumerate common required packages, including the large shiny package and its dependencies
commonPackages <- c(
    "shiny",   # obvious
    "yaml",    # required to load the app library list
    "shinyjs", # used to support user authentication
    "httr",
    "urltools",
    "digest",
    "shinydashboard", # additional shiny support packages
    "shinyBS"
)

# install missing common packages
getRPackages <- function(lib) {
    if(is.null(lib)) character() 
    else list.dirs(lib, full.names = FALSE, recursive = FALSE)
}
installMissingPackages <- function(packages){
    existingPackages <- unique(unlist(sapply(.libPaths(), getRPackages)))
    newPackages <- packages[!(packages %in% existingPackages)]
    if(length(newPackages) == 0) return("OK")
    install.packages(
        newPackages, 
        lib = env$PACKAGE_DIR, 
        repos = "https://cloud.r-project.org/",
        Ncpus = as.integer(env$N_CPU)
    )
    "OK"
}
installMissingPackages(commonPackages)

# discover and install app packages
appDirs <- if(is.null(env$APP_GITHUB_REPO) || env$APP_GITHUB_REPO == "") {
    list.dirs(path = env$APPS_DIR, full.names = TRUE, recursive = FALSE) # multi-app installation
} else {
    repo <- gsub(".git", "", basename(env$APP_GITHUB_REPO)) # single-app installation
    file.path(env$APPS_DIR, repo)
}
if(is.na(appDirs) || !dir.exists(appDirs[1])){
    message("no installed apps, no additional packages to install")
    q('no')
}
appPackages <- unique(unlist(sapply(appDirs, function(appDir){
    appPackagesFile <- file.path(appDir, "install-packages.yml")
    if(!file.exists(appPackagesFile)) return(character())
    unlist(yaml::read_yaml(appPackagesFile))  
})))
if(is.null(appPackages) || length(appPackages) == 0){
    message("no app R package requirements found, no additional packages to install")
    q('no')
}
installMissingPackages(appPackages)
