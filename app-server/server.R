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
    if(length(queryString) > 0) updateQueryString("?", mode = "push") # clear the url

    # public servers demand user authentication; ui is redirecting
    if(serverEnv$REQUIRES_AUTHENTICATION &&  # allow all local page loads
       is.null(queryString$code) && # user has successfully logged in with Globus, this is an auth response
       !file.exists(sessionFile) && # this is a session with prior auth
       !restricted # this is a user's first encounter, show login help
    ) return()

    # source the code that defines a session
    sessionInput <- input
    sessionSession <- session

    print("SERVER GOT TO HERE")

    # source("server/initializeSession.R", local = TRUE)
    # if(!initializeSessionSuccess) return( show(CONSTANTS$apps$scriptSourceError) )
    # show(if(MbRAM_beforeStart > serverEnv$MAX_MB_RAM_BEFORE_START)
    #      CONSTANTS$apps$serverBusy else CONSTANTS$apps$launchPage)        
    # createSpinner() # create the loading spinner
    # source("server/observeAuthentication.R", local = TRUE)
    # source("server/initializeLaunchPage.R", local = TRUE)
    # source("server/observeLoadRequest.R", local = TRUE)
    # source("server/onSessionEnded.R", local = TRUE)
}

#----------------------------------------------------------------------
# MAIN SERVER function: set/get session cookie and act on its values
#----------------------------------------------------------------------
server <- function(input, output, session){
    message('--------- RUNNING server.R::server() ---------')

    # send message to javascript to set the session key (won't override an existing session)
    session$sendCustomMessage('initializeSession', list(
        value = nonce()
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
                    data  = list(value = 1)
                )
            )
            serverFn(input, output, session,
                     sessionKey, sessionFile,
                     cookie, restricted = FALSE) 
        }
    })  
}
