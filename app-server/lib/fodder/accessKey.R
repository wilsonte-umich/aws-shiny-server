#----------------------------------------------------------------------
# access key helper functions
#----------------------------------------------------------------------

# process the access key offered by the user
handleAccessKeyResponse <- function(sessionKey, queryString){
    stateKey <- getAuthenticationStateKey(sessionKey)
    stateMatch <- stateKey == queryString$state
    if(!stateMatch) return(FALSE)
    load(file = getAuthenticatedSessionFile('state', stateKey))
    keyMatch <- FALSE
    config <- serverConfig$keys
    for(keyName in names(config)){
        key <- config[[keyName]]
        x <- strsplit(key$hash, '_')[[1]] 
        salt <- x[1]
        expectedHash <- x[2]
        saltedKey <- paste0(salt, state$accessKey)
        testHash <- digest::digest(saltedKey)
        if(testHash == expectedHash){
            keyMatch <- TRUE

            # record authenticated user information
            authenticatedUserData <- list()
            authenticatedUserData$user <- list(keyName = keyName, displayName = keyName)

            # record the authorizations for the newly authenticated user
            authenticatedUserData$authorization <- key

            # save user data in a session file
            save(authenticatedUserData, file = getAuthenticatedSessionFile('session', sessionKey)) # cache user session by sessionKey # nolint
            break
        }
    }
    keyMatch
}

# keys:
#   team_members:
#     hash: 5fr9uc24m0eqjbgxp1wnva6hd8okiltz_df6e4823c701569a0a2adb899f041e9d
#     paths: 
#       read: all
#       write: demo2
#     apps: all
