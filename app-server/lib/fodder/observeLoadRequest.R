#----------------------------------------------------------------------
# target app loading; activated by file inputs on launch page
#----------------------------------------------------------------------
loadRequest <- reactiveVal(list())
retryLoadRequest <- reactiveVal(0)
appApprovalFile <- file.path(serverEnv$DATA_DIR, "mdi-app-approval.yml")
getAppApprovalKey <- function(app){
    app <- parseAppSuite(appDirs[[app]])
    paste(app$suite, app$name, sep = " / ")
}
confirmAppApproval <- function(appKey, callback, ...){
    showUserDialog(                                     
        "Approve App for Use", 
        ...,
        tags$p("Click 'OK' to confirm that you understand and accept the risks ", 
                "of using the following app on your computer or server and wish to proceed:"),
        tags$p(
            style = "margin-left: 2em; font-weight: bold;",
            appKey
        ), 
        callback = callback,
        size = "m", 
        type = 'okCancel',
        removeModal = FALSE # audit function handles modal closing
    )
}

# act on an authorized and approved app load request
executeLoadRequest <- function(loadRequest){
    app$NAME <<- loadRequest$app
    app$DIRECTORY <<- appDirs[[app$NAME]] # app working directory, could be definitive or developer 

    # initialize the requested app   
    updateSpinnerMessage(session, "reading config") 
    app$sources <<- parseAppDirectory(app$DIRECTORY)
    app$config <<- read_yaml(file.path(app$DIRECTORY, 'config.yml'))
    gitStatusData$app$name <- app$NAME
    gitStatusData$app$version <- if(is.null(app$config$version)) "na" else app$config$version
    gitStatusData$suite$dir <- R.utils::getAbsolutePath( file.path(app$DIRECTORY, '..', '..', '..') )
    gitStatusData$suite$name <- basename(gitStatusData$suite$dir)
    gitStatusData$suite$versions <- getAllVersions(gitStatusData$suite$dir)
    gitStatusData$suite$head <- getGitHead(gitStatusData$suite)

    # TODO: check working version, bookmark version, latest version, etc.
    # offer user the option to switch to matching legacy or latest version, after checking for breaking changes
    # if bookmark being loaded, check bookmark versions against latest (and working if different)
    # if date file being loaded (i.e, without prior version info), check working against latest

    # load dependency scripts first
    # check and set versions of suite dependencies prior to script loading
    sessionEnv$sourceLoadType <- "app"
    updateSpinnerMessage(session, "loading dependencies")
    gitStatusData$dependencies <- getSuiteDependencies(gitStatusData$suite$dir)
    abortDependency <- function(repoDir){
        releaseMdiGitLock(repoDir)
        NULL
    }
    for(i in seq_along(gitStatusData$dependencies)){
        x <- gitStatusData$dependencies[[i]]
        if(!is.null(x$version)){
            waitForRepoLock(repoDir = x$dir)
            setMdiGitLock(x$dir)
            git2r::checkout(x$dir, x$version, create = FALSE)            
        }
        dirs <- parseExternalSuiteDirs(x$name)
        if(is.null(dirs)) return( abortDependency(x$dir) )
        loadSuccess <- loadAllRScripts(dirs$suiteGlobalDir, recursive = TRUE)
        if(!loadSuccess) return( abortDependency(x$dir) )
        loadSuccess <- loadAllRScripts(dirs$suiteSessionDir, recursive = TRUE)
        if(!loadSuccess) return( abortDependency(x$dir) )  
        gitStatusData$dependencies[[i]]$versions <- getAllVersions(x$dir)
        gitStatusData$dependencies[[i]]$head <- getGitHead(x)        
        if(!is.null(x$version)) releaseMdiGitLock(x$dir)
    }

    # load all relevant session scripts in reverse precedence order
    #   global, then session, folders were previously sourced by initializeSession.R on page load
    updateSpinnerMessage(session, "loading app scripts")
    loadSuccess <- loadAllRScripts(app$sources$suiteGlobalDir, recursive = TRUE)
    if(!loadSuccess) return(NULL)
    loadSuccess <- loadAppScriptDirectory(app$sources$suiteSessionDir)
    if(!loadSuccess) return(NULL)
    loadSuccess <- loadAppScriptDirectory(app$DIRECTORY) # add all scripts defined within the app itself; highest precedence # nolint
    if(!loadSuccess) return(NULL)
    sessionEnv$sourceLoadType <- ""

    # validate and establish the module dependency chain
    updateSpinnerMessage(session, "building dependency chain")
    failure <- initializeAppStepNamesByType()
    if(!is.null(failure)){
        message()
        message(rep('!', 80))
        message(paste(app$NAME, 'app config error:', failure))
        message(rep('!', 80))
        message()
        return( stopSpinner(session) )
    }
    initializeDescendants()

    # determine the best way to initialize the UI for this user and incoming file
    nAppSteps <- length(app$config$appSteps)
    appStepNames <- names(app$config$appSteps)
    userFirstVisit <- is.null(cookie) || is.null(cookie[[app$NAME]]) || cookie[[app$NAME]] != 'true'
    assign('isColdStart', !is.null(loadRequest$coldStart) && loadRequest$coldStart, envir = sessionEnv)
    isBookmarkFile <- !isColdStart && loadRequest$file$type == "bookmark"
    showSplashScreen <- !isBookmarkFile && (nAppSteps == 0 || (userFirstVisit && !serverEnv$IS_DEVELOPER))      
    splashScreenName <- 'appName' # the name of the app overview tab
    selectedStep <- if(showSplashScreen) splashScreenName else {
        path <- loadRequest$file$path
        stepName <- if(isBookmarkFile) getTargetAppFromBookmarkFile(path, function(...) NULL)$step else NULL
        if(is.null(stepName)) appStepNames[1] else stepName
    }
    nAboveFold <- if(selectedStep == splashScreenName) 1 else which(appStepNames == selectedStep)  
    if(length(nAboveFold) == 0) { # failsafe in case bookmark provides a bad step name
        selectedStep <- splashScreenName
        nAboveFold <- 1 # even if showing splash screen, load app step 1 to handle the incoming source file
    }

    # initialize app-specific data paths
    initializeAppDataPaths()      

    # initialize the app-specific sidebar menu
    updateSpinnerMessage(session, "building UI")
    removeUI(".sidebar-menu li, #saveBookmarkFile-saveBookmarkFile, .sidebar-status",
             multiple = TRUE, immediate = TRUE)
    insertUI(".sidebar-menu", where = "beforeEnd", immediate = TRUE,
        ui = tagList(
            menuItem(tags$div(app$config$name, class = "app-name"), tabName = "appName"), # app name, links to Overview
            if(nAppSteps > 0) lapply(1:nAppSteps, sequentialMenuItem), # app-specific steps
            saveYourWorkLinks()  # enable state bookmarking
        )
    )      

    # initialize the app-specific content panels
    removeUI(".tab-content", immediate = TRUE)
    insertUI(".content",  where = "beforeEnd", immediate = TRUE,   
        ui = eval({ 
            tabItemsList <- getAppOverviewHtml(nAppSteps) # brief general description of app
            if(nAppSteps > 0) for(i in 1:nAppSteps){ # one tab item per app-specific analysis step
                tabItemsList[[length(tabItemsList) + 1]] <- sequentialTabItem(i)
            }  
            do.call(tabItems, unname(tabItemsList)) # do.call syntax necessitated shinydashboard limitation  
        })
    )

    # initialize the record lock lists
    updateSpinnerMessage(session, "initializing bookmarks and locks")
    locks <<- intializeStepLocks()
    
    # enable bookmarking; appStep modules react to bookmark
    bookmark <<- bookmarkingServer('saveBookmarkFile', list(), locks) # in the app sidebar
    if(!serverEnv$IS_LOCAL) serverBookmark <<- bookmarkingServer('saveBookmarkToServer', list(shinyFiles = TRUE), locks)

    # load servers for all required appStep modules, plus finally run appServer
    # because this is the slowest initialization step, defer many until after first UI load
    updateSpinnerMessage(session, "loading step servers")
    if(!exists('appServer')) appServer <- function() NULL # for apps with no specific server code
    runModuleServers <- function(startI, endI){
        lapply(startI:endI, function(i){
            stepName <- names(app$config$appSteps)[i]
            reportProgress(paste('loadStepModuleServers', stepName))            
            step <- app$config$appSteps[[i]]
            server <- get(paste0(step$module, 'Server'))
            if(is.null(step$options)) step$options <- list()
            step$options$stepNumber <- i
            app[[stepName]] <<- server(stepName, step$options, bookmark, locks)
            addStepReadinessObserver(stepName)
        })
    }
    if(nAppSteps > 0){
        if(nAboveFold > 0) runModuleServers(1, nAboveFold)
        if(nAppSteps > nAboveFold) {
            reportProgress('-- THE FOLD --')
            future({ Sys.sleep(2) }) %...>% (function(x) {
                runModuleServers(nAboveFold + 1, nAppSteps)
                appServer()
            })   
        } else appServer()       
    } else appServer() 

    # select the first content page
    updateTabItems(session, 'sidebarMenu', selected = selectedStep) 
    
    # enable a universal action to close any modal dialog/popup
    addRemoveModalObserver(input)    

    # push the initial file upload to the app via it's first step module
    updateSpinnerMessage(session, "loading data")
    if(!isColdStart && loadRequest$file$type == CONSTANTS$sourceFileTypes$bookmark){
        bookmark$file <- loadRequest$file$path
        nocache <- loadRequest$file$nocache
        if(is.null(nocache) || !nocache) bookmarkHistory$set(file=bookmark$file) # so loaded bookmarks appear in cache list # nolint
    } else {
        firstStep <- app[[ names(app$config$appSteps)[1] ]] # cold-startable apps must handle empty loadRequest$file  
        firstStep$loadSourceFile(loadRequest$file, suppressUnlink = loadRequest$suppressUnlink)
    } 

    # clean up
    stopSpinner(session, 'executeLoadRequest')
    observeLoadRequest$destroy() # user has to reload page to reset to launch page once an app is loaded
    session$sendCustomMessage('setDocumentCookie', list(
        name  = app$NAME,
        data  = list(value = TRUE, isServerMode = serverEnv$IS_SERVER),
        nDays = 365
    ))    
}

# audit the requested app, i.e., check for content requiring additional approval, etc.
auditLoadRequest <- function(loadRequest){ 
    if(serverEnv$IS_SERVER) return(executeLoadRequest(loadRequest))

    # run the code audit
    updateSpinnerMessage(session, "auditing app code")
    appDir <- appDirs[[loadRequest$app]]
    sharedDir <- R.utils::getAbsolutePath( file.path(appDir, '..', '..', 'shared') )
    scripts <- c(
        list.files(appDir,    '\\.R$', full.names = TRUE, recursive = TRUE),
        list.files(sharedDir, '\\.R$', full.names = TRUE, recursive = TRUE)
    )
    flags <- list( # use list for future consideration of other flag types
        system = FALSE
    )
    for(script in scripts) {
        x <- readChar(script, file.info(script)$size)
        if(!flags$system) flags$system <- grepl('[-{}:;\\s](system|system2|shell)\\s*\\(', x, perl = TRUE)
    }

    # prompt for user approval if flags found
    appApprovals <- read_yaml(appApprovalFile) 
    appKey <- getAppApprovalKey(loadRequest$app)    
    if(
        flags$system && (is.null(appApprovals[[appKey]]$system) || !appApprovals[[appKey]]$system)
    ){
        confirmAppApproval(
            appKey = appKey, 
            callback = function(...) {
                if(flags$system) appApprovals[[appKey]]$system <<- TRUE
                write_yaml(appApprovals, appApprovalFile)
                removeModal()
                executeLoadRequest(loadRequest)
            }, 
            tags$p("The following flags were raised on an audit of the app's code."), 
            tags$ul(
                if(flags$system) tags$li(
                    "function calls that would execute commands on your MDI server operating system"
                ) else ""
            )
        )
    } else { # skip prompt for previously approved apps
        removeModal()
        executeLoadRequest(loadRequest)
    }
}

# initialized a request to load an app
observeLoadRequest <- observeEvent({ 
    loadRequest()
    retryLoadRequest()
}, {
    loadRequest <- loadRequest() 
    req(loadRequest$app) 

    # authorize the requested app
    startSpinner(session, 'observeLoadRequest', message = "authorizing")    
    if(serverEnv$REQUIRES_AUTHENTICATION && !isAuthorizedApp(loadRequest$app)) {
        stopSpinner(session, 'observeLoadRequest: unauthorized')
        showUserDialog(
            "Unauthorized App", 
            tags$p(paste("You are not authorized to use the", loadRequest$app, "app.")), 
            type = 'okOnly'
        )
        return()
    }

    # get user approval to load an app for the first local/remote use  
    # public server apps are implicitly approved by the maintainer
    if(serverEnv$IS_SERVER) return(auditLoadRequest(loadRequest))
    updateSpinnerMessage(session, "checking approval")
    appApprovals <- if(file.exists(appApprovalFile)) read_yaml(appApprovalFile) else list()    
    appKey <- getAppApprovalKey(loadRequest$app)
    if(
        is.null(appApprovals[[appKey]]) || 
        is.null(appApprovals[[appKey]]$app) ||
        !appApprovals[[appKey]]$app
    ){
        confirmAppApproval(
            appKey = appKey, 
            callback = function(...) {
                if(is.null(appApprovals[[appKey]])) appApprovals[[appKey]] <<- list()
                appApprovals[[appKey]]$app <<- TRUE
                write_yaml(appApprovals, appApprovalFile)
                auditLoadRequest(loadRequest)
            }, 
            tags$p(paste(
                "MDI apps can access the file system and execute commands on your computer.",
                "It is essential that you trust the people who develop the apps you run."
            )), 
            tags$p("For more information about MDI security, see:"), 
            tags$p(tags$a(
                style = "margin-left: 2em;",
                href = "https://midataint.github.io/docs/registry/00_index/", 
                target = "Docs",
                "MDI Tool Suite Registry"
            )),
            tags$p(tags$a(
                style = "margin-left: 2em;",
                href = "https://midataint.github.io/mdi-desktop-app/docs/security-notes.html", 
                target = "Docs",
                "MDI Desktop Security Notes"
            ))
        )
    } else { # skip prompt for previously approved apps
        auditLoadRequest(loadRequest)
    }
})
