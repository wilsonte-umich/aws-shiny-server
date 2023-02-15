#----------------------------------------------------------------------
# Globus API constants
#----------------------------------------------------------------------
globusAuthEndpoints <- oauth_endpoint(
    base_url  = "https://auth.globus.org/v2/oauth2",
    authorize = "authorize",
    access    = "token"
)
globusHelperPages <- list(
    logout = "https://auth.globus.org/v2/web/logout/"
)
globusPublicKey <- if(!serverEnv$IS_GLOBUS) NULL else jose::read_jwk( content(GET("https://auth.globus.org/jwk.json"))[[1]][[1]] ) # nolint

#----------------------------------------------------------------------
# define the web application client acting on behalf of a user
#----------------------------------------------------------------------
globusClient <- oauth_app(
    appname = "globus",
    key     = serverConfig$oauth2$client$key,
    secret  = serverConfig$oauth2$client$secret,
    redirect_uri = serverEnv$SERVER_URL
)
globusUserScopes <- paste( # the user grants permissions to the client to ...
    "openid",   # ... read their identifying information
    "email"
    # ,    # includes $sub and $email for identity and linked identities in $identity_set
    # "profile"   # profile adds $name (e.g. John Doe) and $identity_provider[_display_name]
)
