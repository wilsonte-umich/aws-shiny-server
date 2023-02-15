#----------------------------------------------------------------------
# top level app server code
# re-sourced by run_server.R > Shiny::runApp() whenever this script changes
# server() function called once per Shiny session
#----------------------------------------------------------------------
# message('--------- SOURCING shared/server.R ---------')

# serverFn called by server() below based on priorCookie status
serverFn <- function(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted=FALSE){

    # collect client data
    queryString <- parseQueryString(isolate(session$clientData$url_search))
    if(!serverEnv$IS_SERVER) isolate({
        port <- session$clientData$url_port
        if(!is.null(port) && port != "") setServerPort(as.integer(port))
    })

    # enforce single-user access when running remotely on a shared resource
    if(!checkMdiRemoteKey(queryString)) return(NULL)
    if(length(queryString) > 0) updateQueryString( # clear the url
        paste0("?", getRemoteKeyQueryString()), 
        mode = "push"
    )

    # public servers demand user authentication; ui is redirecting
    if(serverEnv$REQUIRES_AUTHENTICATION &&  # allow all local page loads
       is.null(queryString$code) && # user has successfully logged in with Globus, this is an auth response
       !file.exists(sessionFile) && # this is a session with prior auth
       !restricted # this is a user's first encounter, show login help
    ) return()

    # source the code that defines a session
    sessionInput <- input
    sessionSession <- session
    source("server/initializeSession.R", local = TRUE)
    if(!initializeSessionSuccess) return( show(CONSTANTS$apps$scriptSourceError) )
    show(if(MbRAM_beforeStart > serverEnv$MAX_MB_RAM_BEFORE_START)
         CONSTANTS$apps$serverBusy else CONSTANTS$apps$launchPage)        
    createSpinner() # create the loading spinner
    source("server/observeAuthentication.R", local = TRUE)
    source("server/initializeLaunchPage.R", local = TRUE)
    source("server/observeLoadRequest.R", local = TRUE)
    source("server/onSessionEnded.R", local = TRUE)
    # observeEvent(input$loadDebugRestart, {
    #     # Sys.setenv(MDI_FORCE_RESTART = "TRUE")
    #     stopApp()
    # })
    # observeEvent(input$loadDebugMessage, {
    #     message('input$loadDebugMessage 222')
    # })
}

#----------------------------------------------------------------------
# MAIN SERVER function: set/get session cookie and act on its values
#----------------------------------------------------------------------
server <- function(input, output, session){
    # message('--------- RUNNING shared/server.R::server() ---------')
    # message()

    # send message to javascript to set the session key (won't override an existing session)
    session$sendCustomMessage('initializeSession', list(
        value = nonce(),
        isServerMode = serverEnv$IS_SERVER
    ))

    # listen for the response and act accordingly
    initializationObserver <- observeEvent(input$initializeSession, {
        initializationObserver$destroy()

        # parse information from js
        cookie <- parseCookie(input$initializeSession$cookie)
        priorCookie <- parseCookie(input$initializeSession$priorCookie)
        sessionKey <- getSessionKeyFromNonce(input$initializeSession$sessionNonce) # cannot rely on sessionKey if HttpOnly # nolint
        sessionFile <- getAuthenticatedSessionFile('session', sessionKey)
        isLoggedIn <- file.exists(sessionFile)   

        # new public user, show the help page only
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
                    data  = list(value = 1, isServerMode = serverEnv$IS_SERVER)
                )
            )
            serverFn(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted = FALSE) 
        }
    })  
}
