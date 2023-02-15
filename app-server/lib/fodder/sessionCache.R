#----------------------------------------------------------------------
# establish a server (not session) level store for session and state recovery between page calls
#----------------------------------------------------------------------

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

# function called on each session end to purge old cache entries
purgeSessionCache <- function(){
    sesionFiles <- list.files(path = serverEnv$SESSIONS_DIR, full.names = TRUE, include.dirs = TRUE)
    for(sessionFile in sesionFiles){
        mtime <- file.info(sessionFile)$mtime
        diffmtime <- difftime(Sys.time(), mtime, units = "days")
        if(diffmtime > 2) file.remove(sessionFile) # 2 days
    }
}
