#----------------------------------------------------------------------
# execute OAuth2 authorization code grant via httr
# provides user authentication but NOT app authorization
#----------------------------------------------------------------------

# get 'code', 'state' and other flow control parameters from a cookie
parseCookie <- function(cookie){ 
    nullCookie <- list()
    if(is.null(cookie) || cookie == "") return( nullCookie )
    keyValuePairs <- strsplit(cookie, '; ')[[1]]
    if(length(keyValuePairs) == 0) return( nullCookie )
    cookie <- list()
    for(kvp in keyValuePairs){
        kvp <- strsplit(kvp, '=')[[1]]
        cookie[[kvp[1]]] <- kvp[[2]]
    }
    cookie # a named list, similar to parseQueryString() 
}

# make a ~unique key (could also use UUID package)
nonce <- function() digest(paste(
    Sys.time(),
    paste0(sample(c(letters, LETTERS, 0:9), 50), collapse = "")
))

# simple lookup from a nonce to a sessionKey for recovering key in server.R from value set in ui.R
sessionNonceCache <- list()
setSessionKeyNonce <- function(sessionKey){
    sessionNonce <- nonce()
    sessionNonceCache[[sessionNonce]] <<- if(is.null(sessionKey)) "no_key" else sessionKey
    sessionNonce
}
getSessionKeyFromNonce <- function(sessionNonce){
    sessionKey <- sessionNonceCache[[sessionNonce]]
    sessionNonceCache[[sessionNonce]] <<- NULL
    sessionKey
}
purgeSessionCache <- function(){
    sesionFiles <- list.files(path = serverEnv$SESSIONS_DIR, full.names = TRUE, include.dirs = TRUE)
    for(sessionFile in sesionFiles){
        mtime <- file.info(sessionFile)$mtime
        diffmtime <- difftime(Sys.time(), mtime, units = "days")
        if(diffmtime > 2) file.remove(sessionFile) # 2 days
    }
}

# standardized session file paths
getAuthenticatedSessionFile <- function(type, key){ 
    if(is.null(key)) key <- "XXXXXXXX"
    file.path(serverEnv$SESSIONS_DIR, paste(type, key, sep = "-"))
}

# derive a unique and opaque one-way hash of a signed sessionKey for use as a state parameter
getAuthenticationStateKey <- function(sessionKey){
    digest(paste(sessionKey, serverEnv$SERVER_ID))
}
getUserSessionState <- function(sessionKey){
    stateKey <- getAuthenticationStateKey(sessionKey)
    stateFile <- getAuthenticatedSessionFile('state', stateKey)
    if(!file.exists(stateFile)) return(list())
    load(stateFile)
    state
}

# Google API
getOauth2Config <- function(){
    list(
        endpoints = oauth_endpoints("google"),
        app = oauth_app(
            appname = "aws-shiny-server",
            key     = serverEnv$GOOGLE_CLIENT_ID,
            secret  = serverEnv$GOOGLE_CLIENT_SECRET,
            redirect_uri = serverEnv$SERVER_URL
        ),
        scope = "https://www.googleapis.com/auth/userinfo.email"
    )
}

# initialize OAuth2 by redirecting user to auth and login
getOauth2RedirectUrl <- function(sessionKey, state = list()){
    stateKey <- getAuthenticationStateKey(sessionKey)
    save(state, file = getAuthenticatedSessionFile('state', stateKey))
    config <- getOauth2Config()
    oauth2.0_authorize_url(
        endpoint = config$endpoints,
        app      = config$app, 
        scope    = config$scope,
        state    = stateKey
    )
}
redirectToOauth2Login <- function(sessionKey, state = list()){
    redirect <- sprintf("location.replace(\"%s\");", getOauth2RedirectUrl(sessionKey, state))
    tags$script(HTML(redirect))
}

# process the OAuth2 code response by turning it into tokens
handleOauth2Response <- function(sessionKey, queryString){
    stateMatch <- getAuthenticationStateKey(sessionKey) == queryString$state
    if(stateMatch){ # validate state to prevent cross site forgery
        config <- getOauth2Config()
        access_token <- oauth2.0_access_token( # completes the OAuth2 authorization sequence
            endpoint = config$endpoints, # returns different tokens on each call
            app      = config$app,       # access tokens have expires_in = 172800 seconds = 48 hours
            code     = queryString$code
        )

        # record authenticated user information
        authenticationData <- list(
            token = convertOauth2Token(access_token)
        )
        tryCatch({
            req <- GET(
                "https://www.googleapis.com/oauth2/v1/userinfo",
                httr::config(token = authenticationData$token)
            )
            stop_for_status(req)
            userinfo <- content(req)
            if(!is.null(userinfo$verified_email) || userinfo$verified_email){
                authenticationData$user <- userinfo
                save(authenticationData, file = getAuthenticatedSessionFile('session', sessionKey)) # read at next load
            }
        }, error = function(e){
            print(e)
        }) 
    } else {
        message('!! OAuth2 state check failed !!')   
    }
    stateMatch
}

# convert tokens
convertOauth2Token <- function(token){
    config <- getOauth2Config()
    oauth2.0_token(
        endpoint    = config$endpoints,
        app         = config$app,
        credentials = token,
        cache = FALSE # handled elsewhere
    )
}
