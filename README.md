# aws-shiny-server

This repository helps you easily host an R Shiny web app
from an AWS server instance. The installation supports:

- https/SSL/TLS encyption for secure access via LetsEncrypt
- a session cookie you can use for tracking user sessions
- complete control of private information such as keys, etc.

A main alternative is to use <https://shinyapps.io>, which is a better solution for many. 
However, sometimes you want to launch an app on an inexpensive public 
host over which you have a higher degree of control.

## General description

### Microservices run as Docker containers

The web server is run as a set of microservices from within
Docker containers. 

- <https://www.docker.com/>

One container runs the Traefik reverse proxy/load balancer
and routes requests to the other microservices.

- <https://docs.traefik.io/>

Other containers run the session initializer and the R Shiny app, over 
one or more R processes. This repository has all files needed to build 
and manage all microservice images.

## Server setup

### Use an available Amazan Machine Image

The recommended way to start a new app server on AWS
is to launch a new instance from one of our pre-installed AMIs:

- <https://pending>

Log in as you would to any other AWS instance and continue to configure your app, below.

### Create a new server instance from scratch

If you prefer, you can also install and configure 
aws-shiny-server from scratch.

1. launch an appropriate instance from an Ubuntu Linux AMI, with at least 2 GB RAM
2. log into the instance using any tool to get a command prompt
3. execute, in order:

```sh
cd /srv # move to the server installation directory
sudo git clone https://github.com/wilsonte-umich/aws-shiny-server.git # clone this repo
sudo chown -R ubuntu aws-shiny-server # set permissions
cd aws-shiny-server
./server          # show command help
./server setup    # install Docker, set additional paths
newgrp docker     # activate the current session to allow docker access
./server build    # build the base-level Docker containers (without your app yet)
./server install  # install common R packages
```

Once you have run the `server setup` command, the `server` utility
will be availbe to you at any command prompt.

## Configure your web server details

Edit file the server configuration file with information about
yourself and your desired server properties - follow the instructions in the file:

```sh
server config  # edits file /srv/private/server-config.sh
```

## Setting up your app on the server

### Copy your app code to the instance

Use the following command to clone the git repository that contains your app code:

```sh
server clone # clones the repository set in server-config.sh, if any
```

You will need to provide credentials if your repository is private.

Alternatively, use whatever method you'd like to get your Shiny app on your AWS instance.

### App configuration requirements

The following requirements must be met for your app to be properly
recognized and installed:

- the app root directory must be: `/srv/app/<your-app-name>`
- the app root directory must contain files:
    - `install-packages.yml` = a simple list of the unquoted names of the R pacakages your app requires
    - `xxxx`

## Install the app for use

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

After running `server up`, wait a minute or two and your app should
be running at the URL you provided in `server-config.sh`.

## Debug your app code

Ordinarily, your app runs in the background as a demon. To see your app's
R output for debugging purposes use:

```sh
server down      # stop the server
server up debug  # start the server in interactive mode
# hit Ctrl-C to exit
```
