#----------------------------------------------------------------------
# authentication/httr helper functions
#----------------------------------------------------------------------

# make a ~unique key (could also use UUID package)
nonce <- function(){ 
    digest(paste(
        Sys.time(),
        paste0(sample(c(letters, LETTERS, 0:9), 50), collapse = "")
    ))
}

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

# standardized session file paths
getAuthenticatedSessionFile <- function(type, key){ 
    if(is.null(key)) key <- "XXXXXXXX"
    file.path(serverEnv$SESSIONS_DIR, paste(type, key, sep = "-"))
}

# derive a unique and opaque one-way hash of a signed sessionKey for use as a state parameter
getAuthenticationStateKey <- function(sessionKey){
    digest(paste(sessionKey, serverId))
}
getUserSessionState <- function(sessionKey){
    stateKey <- getAuthenticationStateKey(sessionKey)
    stateFile <- getAuthenticatedSessionFile('state', stateKey)
    if(!file.exists(stateFile)) return(list())
    load(stateFile)
    state
}

# email wildcard matching
isEmailMatch <- function(email, emailList){
    if(is.null(email) || # check for valid inputs
       is.null(emailList) || 
       !grepl('@', email)) return(FALSE)
    if(email %in% emailList) return(TRUE) # 1-to-1 matching
    if("*@*" %in% emailList) return(TRUE) # matching to all authenticated users
    domain <- rev(strsplit(email, '@')[[1]])[1]
    email <- paste('*', domain, sep = '@')
    if(email %in% emailList) return(TRUE) # email domain matching, e.g., institution matching
    FALSE # user is authenticated but not authorized
}
