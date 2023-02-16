#-------------------------------------------------------------
# REQUIRED
#-------------------------------------------------------------

# email address of the contact person for SSL/TLS security
export WEBMASTER_EMAIL="admin@example.org"

# URL (i.e., domain name, without the https://) of your web server
# you can register your domain via Amazon Web Services (AWS) Route 53
export WEB_DOMAIN="example.org"

# version of R used to run the web server and all apps
export R_VERSION="4.2.0"

# number of R Shiny server processes to run
# 1 process per CPU is common, but you can overload or leave processors free for asynchronous tasks
export N_SERVER_PROCESSES=1

#-------------------------------------------------------------
# OPTIONAL
#-------------------------------------------------------------

# the URL of the GitHub repository that carries your _single_ Shiny app
# see documentation for repo requirements
# alternatively, you may populate /srv/apps/<YOUR_APP_NAME> another way
# leave this entry blank if your server will host multiple apps, which must be added manually
export APP_GITHUB_REPO=""

# the parameters that define your Google web app
# see: 
#    https://console.cloud.google.com/
#    https://developers.google.com/identity/protocols/oauth2
# if specified, these will be used to _authenticate_ users (_authorization_ is up to your app!)
# if left blank, your server and apps will be accessible by anyone on the internet
export GOOGLE_CLIENT_ID=""
export GOOGLE_CLIENT_SECRET=""
