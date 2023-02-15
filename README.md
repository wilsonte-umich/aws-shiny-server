# aws-shiny-server

This repository helps you easily host one or more R Shiny web apps
from an AWS server instance. The installation supports:

- https/SSL/TLS encryption for secure access via LetsEncrypt
- a session cookie you can use for tracking user sessions
- complete control of private information such as keys, etc.
- user authentication via Google Oauth2 login

The web server is run as a set of microservices from within
[Docker containers](https://www.docker.com/). One container runs the [Traefik](https://docs.traefik.io) reverse proxy/load balancer
and routes requests to the other microservices. Other containers run the session initializer and the R Shiny app(s), over 
one or more R processes. This repository has all files needed to build 
and manage all microservice images.

A main alternative is to use <https://shinyapps.io>, which is a better solution for many. 
However, sometimes you want to launch an app on an inexpensive public 
host over which you have a higher degree of control.

## Server setup

### Use an available Amazon Machine Image

The recommended way to start a new app server on AWS
is to launch a new instance from one of our pre-installed AMIs:

- [aws-shiny-server AWS AMIs](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Images:visibility=public-images;search=:aws-shiny-server)

Log in as you would to any other AWS instance and continue to configure your app as described below.

### Create a new server instance from scratch

If you prefer, you can also install and configure 
aws-shiny-server from scratch.

1. Launch an appropriate instance from an Ubuntu Linux AMI, with at least 2 GB RAM
2. Log into the instance using any SSH utility to get a command prompt
3. Execute, in order:

```sh
cd /srv # move to the server installation directory
sudo git clone https://github.com/wilsonte-umich/aws-shiny-server.git # clone this repo
sudo chown -R ubuntu aws-shiny-server # set permissions
cd aws-shiny-server
./server          # show command help
./server setup    # install Docker, set additional paths
newgrp docker     # activate the current session to allow docker access
bash ~/.bashrc    # enable current session to use server utility directly
./server build    # build the base-level Docker containers (without your app yet)
./server install  # install common R packages
```

Once you have run the `server setup` command, the `server` utility
will be available to you at any command prompt.

## Configure your web server details

Edit file the server configuration file with information about
yourself and your desired server properties - follow the instructions in the file:

```sh
server config  # edits file /srv/private/server-config.sh
```

## Setting up your app(s) on the server

### Copy your app code to the instance

Use the following command to clone a single git repository that contains your app code, as specified in config variable APP_GITHUB_REPO. You will need to provide credentials if your repository is private.

```sh
server clone # clones the repository set in server-config.sh, if any
```

Alternatively, use whatever method you'd like to get your Shiny app on your AWS instance.
If you will host more than one app from the same server, you must leave the APP_GITHUB_REPO config entry blank and manually clone or create all apps.

### App configuration requirements

The following requirements must be met for each app for it to be properly
recognized and installed:

- the app root directory must be: `/srv/apps/<your-app-name>`
- each app root directory must contain files:
    - `install-packages.yml` = a simple list of the unquoted names of the R pacakages your app requires, one line per package
    - either a single script `app.R` or two scripts `ui.R` and `server.R`

The R script(s) that define your app will be sourced into the global environment
after user authentication and app selection. The scripts must declare two typical Shiny functions that define the app:
- `ui <- function(request) ...`
- `server <- function(input, output, session) ...`


## Install the app(s) for use

Once you have your code clone, copied, or written as above, run the following commands.

```sh
server build    # refresh the Docker image builds
server install  # intall the required R packages
```

## Run (and stop) the app server

```sh
server up    # start the server
server down  # stop the server
```

After running `server up`, wait a minute or two and your server should
be running at the URL you provided in `server-config.sh`.

### Debug your app code

Ordinarily, your app runs in the background as a demon. To see your app's
R output for debugging purposes use:

```sh
server down      # stop the server
server up debug  # start the server in interactive mode
# hit Ctrl-C to exit
```

## Server and app security

The aws-shiny-server repository is open-source so you may see exactly 
what the code is - and isn't! - doing. We will never send any information you 
enter into your AWS instance to anyone except for Google user authentication.
Anything you do with our code on your instance is entirely private to you 
and your app users. If you don't trust us, don't use this repository.

Please use the following mechanisms to maintain security of your server
and apps. 

### User authentication and authorization via Google

If you provide values for `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`
in your server configuration file, the first screen users will see 
will ask them to log in via Google Oauth2, i.e., they must have a valid
Google user account. Only _authenticated_ users will be allow to continue.

CRITICALLY, **aws-shiny-server only _authenticates_ users, it does not 
_authorize_ what they may do with your apps!** In other words, aws-shiny-server
will let your app know who someone is, it is up to your app to determine
if that person is allowed to load the app, execute an action, etc., 
based on their email address.

User identity is passed to your app PENDING. Their gmail address
acts as the unique identifier for who that person is, so your
app must somehow maintain a list of allowed email addresses, etc.

### Private data directory

NEVER include any private information such as passwords in a Git repository. 
Place all such information into files in directory `/srv/private` 
which is available to your app in environment variable `PRIVATE_DIR`.
For example:

```R
myData <- read_yaml(file.path(Sys.getenv("PRIVATE_DIR"), "myData.yml"))
# use it
rm(myData)
```
