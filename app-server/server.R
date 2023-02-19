#----------------------------------------------------------------------
# top level app server code
#----------------------------------------------------------------------

# serverFn called by server() below based on priorCookie status
serverFn <- function(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted = FALSE){

    # collect client data
    queryString <- parseQueryString(isolate(session$clientData$url_search))
    if(length(queryString) > 0) updateQueryString("?", mode = "push") # clear the url

    # public servers demand user authentication; ui is redirecting
    if(serverEnv$REQUIRES_AUTHENTICATION &&  # allow all local page loads
       is.null(queryString$code) && # user has successfully logged in with Globus, this is an auth response
       !file.exists(sessionFile) && # this is a session with prior auth
       !restricted # this is a user's first encounter, show login help
    ) return()

    # create some helpful session-level variables for use by apps
    sessionInput <- input
    sessionSession <- session
    sessionEnv <- environment()

    # initialize the user on the page
    if(file.exists(sessionFile)){
        load(sessionFile, envir = sessionEnv) # puts authenticationData in scope
    }

    # select the UI to show, either login button, app selection or the selected/only app
    # app is responsible for authorization, i.e., whether to let the authenticated email use the app
    selectedApp <- reactiveVal(NULL)
    sourceApp <- function(appName){
        appDir      <- file.path(serverEnv$APPS_DIR, appName)
        appFile     <- file.path(appDir, "app.R")
        uiFile      <- file.path(appDir, "ui.R")
        serverFile  <- file.path(appDir, "server.R")
        wwwDir      <- file.path(appDir, "www")
        if(file.exists(appFile)) {
            source(appFile, local = sessionEnv)
        } else {
            source(uiFile, local = sessionEnv)
            source(serverFile, local = sessionEnv)
        }
        if(dir.exists(wwwDir)) for(object in list.files(wwwDir, full.names = TRUE)){ # enable the app's www folder
            file.copy(object, file.path(serverEnv$TOOLS_DIR, "www"), recursive = TRUE)
        } 
    }
    output$awsShinyServer <- renderUI({
        if(restricted){
            observeEvent(input$oauth2LoginButton, {
                url <- getOauth2RedirectUrl(sessionKey) 
                runjs(paste0('window.location.replace("', url, '")'));
            })
            showLoginPage()
        } else {
            appName <- selectedApp()
            if(isTruthy(appName)){
                sourceApp(appName)
                ui <- ui(request) # intercept and apply body attributes, since we already have a <body> tag in place
                if(is.list(ui) && !is.null(ui$name) && ui$name == "body" && is.list(ui$attribs)){
                    if(!is.null(ui$attribs$class)) addClass(selector = "body", class = ui$attribs$class)
                    if(!is.null(ui$attribs$style)) runjs( paste("$('body').attr('style', '", ui$attribs$style, "')") )
                }
                delay(500, server(input, output, session))              
                ui  
            } else {
                appNames <- getAvailableAppNames()
                if(length(appNames) > 1) showAppSelectionPage(input, appNames, selectedApp) 
                else {
                    selectedApp(appNames)
                    NULL
                }
            }
        }
    })

    # aggressive clean up on all session ends
    session$onSessionEnded(function(){
        rm(list = ls(all.names = TRUE, envir = sessionEnv), envir = sessionEnv)        
        purgeSessionCache()
    })
}

#----------------------------------------------------------------------
# MAIN SERVER function: set/get session cookie and act on its values
#----------------------------------------------------------------------
server <- function(input, output, session){

    # send message to javascript to set the session key (won't override an existing session)
    session$sendCustomMessage('initializeSession', list( value = nonce() ))

    # listen for the response sent by javascript and act accordingly
    initializationObserver <- observeEvent(input$initializeSession, {
        initializationObserver$destroy()

        # parse information from js
        cookie      <- parseCookie(input$initializeSession$cookie)
        priorCookie <- parseCookie(input$initializeSession$priorCookie)
        sessionKey  <- getSessionKeyFromNonce(input$initializeSession$sessionNonce)
        sessionFile <- getAuthenticatedSessionFile('session', sessionKey)
        isLoggedIn  <- file.exists(sessionFile)   

        # new public user, show the login content only
        if(serverEnv$REQUIRES_AUTHENTICATION && !isLoggedIn) { 
            serverFn(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted = TRUE)
        
        # definitive page load
        } else {
            if(isLoggedIn && is.null(cookie$hasLoggedIn)) session$sendCustomMessage(
                'setDocumentCookie',
                list(
                    name  = 'hasLoggedIn',
                    data  = list(value = 1)
                )
            )
            serverFn(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted = FALSE) 
        }
    })  
}
