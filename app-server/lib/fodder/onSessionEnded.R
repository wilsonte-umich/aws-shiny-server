#----------------------------------------------------------------------
# session termination actions for server maintenance and logging
#----------------------------------------------------------------------
session$onSessionEnded(function(){
    
    # autosave the users last page state and clean up the bookmarking storr
    if(exists('bookmarkHistory')) isolate( bookmarkHistory$set(name = CONSTANTS$autoSavedBookmark) )
    serverEnv$STORR$gc()

    # delete any session tmp files still on disk
    suppressWarnings(unlink(sessionDirectory, recursive = TRUE, force = TRUE))
    
    # make copies of needed information before running gc/rm
    sessionData <- (list(
        id = sessionId,     
        startTime = sessionStartTime,
        endTime = Sys.time(),
        durationMins = as.numeric(difftime(Sys.time(), sessionStartTime, units = "mins")),
        appName = app$NAME,
        MbRAM_beforeStart = MbRAM_beforeStart,
        MbRAM_beforeEnd = sum(gc()[, 2]),
        logSessionMetadata = logSessionMetadata
    ))
    
    # agressive memory management by clearing session objects
    # shouldn't be necessary, but no harm and helps limits memory leaks
    rm(list = ls(all.names = TRUE, envir = sessionEnv), envir = sessionEnv)        

    # log session metadata
    sessionData <- sessionData$logSessionMetadata(sessionData)

    # release our lock on shiny restart
    nActiveServerSessions <<- nActiveServerSessions - 1    
    nActiveShinySessions  <<- nActiveShinySessions - 1
    
    # do maintenance on the sessionCache
    purgeSessionCache()

    # restart the server if residual RAM is growing (i.e. memory is leaking) and user-safe
    if(!serverEnv$IS_SERVER) return(NULL)
    if(nActiveShinySessions == 0 && # i.e., no other session is currently using this R process
       sessionData$MbRAM_afterEnd > serverEnv$MAX_MB_RAM_AFTER_END) { # i.e., leaky memory has bloated this shiny
        print("server memory threshold exceeded, no active session, restarting server")
        stopApp()
    } 
})
