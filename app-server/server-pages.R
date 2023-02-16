#----------------------------------------------------------------------
# edit this script as desired to customize your server login and app selection pages
#----------------------------------------------------------------------

# login page
# the only requirement here is that there be button, link or other input with id = "oauth2LoginButton"
showLoginPage <- function(){
    fluidPage(
        style = "margin: 0; padding: 0;",        
        tags$div(
            style = "padding: 30px;",
            bsButton("oauth2LoginButton", "Log in using Google", style = "primary", width = "200px")
        )
    )      
}

# app selection page (only called for a multi-app server installation)
# however you construct your page, it must call selectedApp(appName) to load the selected app
showAppSelectionPage <- function(input, appNames, selectedApp){
    fluidPage(
        style = "margin: 0; padding: 0;",  
        tags$div(
            style = "padding: 30px;",
            lapply(seq_along(appNames), function(i) {
                id <- paste("selectApp", i, sep = "-")
                observeEvent(input[[id]], { selectedApp(appNames[i]) }, ignoreInit = TRUE)
                bsButton(id, appNames[i], style = "primary", width = "200px")
            })
        )
    )
}

# support function for listing apps, do not change this code
getAvailableAppNames <- function(){
    appDirs <- if(is.null(serverEnv$APP_GITHUB_REPO) || serverEnv$APP_GITHUB_REPO == "") {
        list.dirs(path = serverEnv$APPS_DIR, full.names = TRUE, recursive = FALSE) # multi-app installation
    } else {
        repo <- gsub(".git", "", basename(serverEnv$APP_GITHUB_REPO)) # single-app installation
        file.path(serverEnv$APPS_DIR, repo)
    }
    if(is.na(appDirs) || !dir.exists(appDirs[1])) return(character())
    unlist(sapply(appDirs, function(appDir){
        if(file.exists(file.path(appDir, "app.R")) ||
           file.exists(file.path(appDir, "ui.R"))) basename(appDir)
        else character()
    }))
}
