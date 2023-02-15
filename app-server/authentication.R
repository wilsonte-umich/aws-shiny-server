#----------------------------------------------------------------------
# execute OAuth2 authorization code grant via httr
# applies to user authorization of web app for login
#----------------------------------------------------------------------

# get 'code', 'state' and other flow control parameters from query string
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

# standardized session file paths
getAuthenticatedSessionFile <- function(type, key){ 
    if(is.null(key)) key <- "XXXXXXXX"
    file.path(serverEnv$DATA_DIR, paste(type, key, sep = "-"))
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
# googlePublicKey <- if(!serverEnv$IS_GLOBUS) NULL else jose::read_jwk( content(GET("https://auth.globus.org/jwk.json"))[[1]][[1]] ) # nolint
getOauth2Config <- function(){
    list(
        endpoint = oauth_endpoint(

            # "auth_uri":"https://accounts.google.com/o/oauth2/auth",
            # "token_uri":"https://oauth2.googleapis.com/token",
            # "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs"

            base_url  = "https://accounts.google.com/o/oauth2",
            authorize = "authorize",
            access    = "token"
        ),
        app = oauth_app(
            appname = "aws-shiny-server",
            key     = serverEnv$GOOGLE_CLIENT_ID,
            secret  = serverEnv$GOOGLE_CLIENT_SECRET,
            redirect_uri = serverEnv$SERVER_URL
        ),
        scope = paste(
            ".../auth/userinfo.email",
        ),
        # publicKey = googlePublicKey,
        urls      = list()
    )
}

# initialize OAuth2 by redirecting user to auth and login
redirectToOauth2Login <- function(sessionKey, state = list()){
    redirect <- sprintf("location.replace(\"%s\");", getOauth2RedirectUrl(sessionKey, state))
    tags$script(HTML(redirect))
}
# called by server.R, only has hashed sessionKey, i.e., stateKey
getOauth2RedirectUrl <- function(sessionKey, state = list()){
    stateKey <- getAuthenticationStateKey(sessionKey)
    save(state, file = getAuthenticatedSessionFile('state', stateKey))
    config <- getOauth2Config()
    oauth2.0_authorize_url(
        endpoint = config$endpoint,
        app      = config$app, 
        scope    = config$scope,
        state    = stateKey
    )
}

# process the OAuth2 code response by turning it into tokens
handleOauth2Response <- function(sessionKey, queryString){
    stateMatch <- getAuthenticationStateKey(sessionKey) == queryString$state
    if(stateMatch){ # validate state to prevent cross site forgery
        config <- getOauth2Config()
        tokens <- oauth2.0_access_token(    # completes the OAuth2 authorization sequence
            endpoint = config$endpoint, # returns different tokens on each call
            app      = config$app,        # access tokens have expires_in = 172800 seconds = 48 hours
            code     = queryString$code
        )

        # record authenticated user information
        authenticatedUserData <- list(tokens = list( 
            auth = convertOauth2Tokens(tokens)
        ))
        authenticatedUserData$user <- jwt_decode_sig(tokens$id_token, config$publicKey) # using the id_token
        authenticatedUserData$user$displayName <- authenticatedUserData$user$email

        # save authenticated and authorized user data in a session file
        save(authenticatedUserData, file = getAuthenticatedSessionFile('session', sessionKey)) # cache user session by sessionKey # nolint
    } else {
        message('!! OAuth2 state check failed !!')   
    }
    stateMatch
}

# convert tokens
convertOauth2Tokens <- function(tokens){
    config <- getOauth2Config()
    oauth2.0_token(
        endpoint    = config$endpoint,
        app         = config$app,
        credentials = tokens,
        cache = FALSE # handled elsewhere
    )
}
