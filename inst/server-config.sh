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
# 1 process per 2 CPUs is a good choice, but you can overload more aggressively
export N_SERVER_PROCESSES=1

#-------------------------------------------------------------
# OPTIONAL
#-------------------------------------------------------------

# the URL of the GitHub repository that carries your Shiny app
# see documentation for repo requirements
# alternatively, you may popuplate /srv/app/<YOUR_APP_NAME> another way
export GITHUB_REPO=""
