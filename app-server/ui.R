#----------------------------------------------------------------------
# set up the UI dashboard and launch page (i.e., the interface for first file upload)
# re-sourced by run_server.R > Shiny::runApp() whenever this script changes
# ui() function called once per Shiny session
#----------------------------------------------------------------------

# STYLES AND SCRIPTS, loaded into html <head>
htmlHeadElements <- tags$head(
    # tags$link(href = "framework.css", rel = "stylesheet", type = "text/css"), # framework js and css
    tags$script(src = "server.js", type = "text/javascript", charset = "utf-8")
)

# LAUNCH PAGE ASSEMBLY: called by ui function (below) as needed
getLaunchPage <- function(cookie, restricted = FALSE){
    fluidPage(
        htmlHeadElements,
        useShinyjs(), # enable shinyjs
        HTML(paste0("<input type=hidden id='sessionNonce' value='", setSessionKeyNonce(cookie$sessionKey), "' />")),
        fluidRow(
            column(12,
                if(restricted){
                    actionButton("oauth2LoginButton", "Login using Google", style = "margin: 1em;")
                } else {
                    "contents pending"
                }
            )
        )
    )  
}

# AUTHENTICATION FLOW CONTROL, i.e., page redirects, associated with authentication interactions
handleLoginResponse <- function(cookie, queryString, handler){
    success <- handler(cookie$sessionKey, queryString)
    getLaunchPage(cookie, restricted = !success)
}
parseAuthenticationRequest <- function(queryString, cookie){

    # handle OAuth2 code response
    if(!is.null(queryString$code)){
        handleLoginResponse(cookie, queryString, handleOauth2Response)
        
    # OAuth2 or other error
    } else if(!is.null(queryString$error)){
        getLaunchPage(cookie, restricted = TRUE)
 
    # determine whether we have an active session ...
    } else if(is.null(cookie$sessionKey)) { # session-initialization service sets the HttpOnly session key
        url <- file.path(serverEnv$SERVER_URL, 'session')
        redirect <- sprintf("location.replace(\"%s\");", url)
        tags$script(HTML(redirect))

    # ... for a known user
    } else if(serverEnv$REQUIRES_AUTHENTICATION && # new session for a public user, show the login page only
              is.null(cookie$hasLoggedIn)){ # false if reloading a current valid session
        getLaunchPage(cookie, restricted = TRUE)

    # check if we have credentials already, server will know how to handle them  
    } else {
        if(file.exists(getAuthenticatedSessionFile('session', cookie$sessionKey))){ # non-cookie check for an authenticated session # nolint
            getLaunchPage(cookie)
        } else {
            redirectToOauth2Login(cookie$sessionKey) # allow oauth2 users to quickly pass authentication via prior SSO
        }
    }
}

#----------------------------------------------------------------------
# MAIN UI function: determine what type of page request this is and act accordingly
#----------------------------------------------------------------------
ui <- function(request){
    queryString <- parseQueryString(request$QUERY_STRING) # parseQueryString is an httr function
    cookie <- parseCookie(request$HTTP_COOKIE) # parseCookie is our helper function
    if(serverEnv$REQUIRES_AUTHENTICATION){ 
        parseAuthenticationRequest(queryString, cookie)
    } else {
        getLaunchPage(cookie)
    }
}
