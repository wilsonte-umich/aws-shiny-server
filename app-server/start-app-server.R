# launch the apps server

serverEnv <- as.list(Sys.getenv())
.libPaths(serverEnv$PACKAGE_DIR)

library(shiny)
library(yaml)
library(shinyjs)
library(httr)
library(urltools)
library(digest)

source("authentication.R")

serverEnv$SERVER_URL <- paste0("https://", serverEnv$WEB_DOMAIN)
serverEnv$REQUIRES_AUTHENTICATION <- isTruthy(serverEnv$GOOGLE_CLIENT_ID) || isTruthy(serverEnv$GOOGLE_CLIENT_SECRET)
serverEnv$SERVER_ID <- sample(1e8, 1)

runApp(
    appDir = '.',
    host = "0.0.0.0",   
    port = 3838, # on _first_ call, could be NULL for port auto-selection by Shiny
    launch.browser = FALSE
)
