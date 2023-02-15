#----------------------------------------------------------------------
# handle login and authentication 
#----------------------------------------------------------------------

# initialize the user on the page
if (file.exists(sessionFile)){
    load(sessionFile, envir = sessionEnv)
    headerStatusData$userDisplayName <- authenticatedUserData$user$displayName
}

# enable the login buttons on the help page
observeEvent(input$oauth2LoginButton, {
    url <- getOauth2RedirectUrl(sessionKey) 
    runjs(paste0('window.location.replace("', url, '")'));
})
observeEvent(input$keyedLoginButton, {
    req(input$accessKeyEntry)
    state <- list(accessKey = input$accessKeyEntry) # don't pass the key, just a transient stateKey, in the redirect url
    stateKey <- getAuthenticationStateKey(sessionKey)
    save(state, file = getAuthenticatedSessionFile('state', stateKey))
    url <- paste0(serverEnv$SERVER_URL, '?state=', stateKey, '&accessKey=', TRUE)
    runjs(paste0('window.location.replace("', url, '")'));
})

# show help on the login page about external authorization sources
observeEvent(input$showLoginHelp, {
    show('login-help')
})

# determine whether session has an authorized user
isAuthorizedUser <- function(){
    !serverEnv$REQUIRES_AUTHENTICATION || # private server users are implicitly authorized
    !is.null(authenticatedUserData$authorization) # doesn't care _what_ is authorized at this stage
}
