#!/bin/bash

#---------------------------------------------------------------
# script to set up an AWS Ubuntu instance for using aws-shiny-server.
#---------------------------------------------------------------
IS_INSTALLED=`which docker`
if [[ "$IS_INSTALLED" != "" && "$1" == "" ]]; then
  echo "server has already been set up"
  exit 1
fi

#---------------------------------------------------------------
# use sudo initially to install resources and configure server as root
#---------------------------------------------------------------

# update system
echo 
echo "updating operating system"
sudo apt-get update
sudo apt-get upgrade -y

# install miscellaneous tools
echo 
echo "installing miscellaneous tools"
sudo apt-get install -y \
  git \
  build-essential \
  tree \
  nano \
  apache2-utils \
  dos2unix \
  nfs-common \
  make \
  binutils

# install Docker, now including docker-compose via plugin
echo 
echo "installing Docker engine"
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
sudo mkdir -p /etc/apt/keyrings  
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# allow current user to control docker without sudo
echo 
echo "adding $USER to docker group"
sudo usermod -aG docker $USER

# set server groups
echo 
echo "creating shiny-edit group"
sudo groupadd shiny-edit
sudo usermod -a -G shiny-edit $USER

# set server paths and permissions
echo 
echo "initializing /srv file tree"
cd /srv
sudo mkdir -p apps    # for app server code
sudo mkdir -p data    # for external data bind-mounted into running instances
sudo mkdir -p private # for non-repository information such as access keys
sudo chown -R $USER     apps data private aws-shiny-server
sudo chmod -R u+rwx      private aws-shiny-server
sudo chgrp -R shiny-edit apps data
sudo chmod -R ug+rwx     apps data

#---------------------------------------------------------------
# continue as regular user (i.e., not sudo) to populate /srv
#---------------------------------------------------------------

# copy web server configuration templates to final location outside of the repo
echo 
echo "copying server config template"
cp aws-shiny-server/inst/server-config.sh private

# add the server executable script to PATH
echo 
echo "adding server utility to PATH"
chmod u+x aws-shiny-server/server
echo -e "\n\nexport PATH=/srv/aws-shiny-server:\$PATH\n" >> ~/.bashrc

# validate and report success
echo
echo "installation summary"
docker --version
docker compose version
echo
tree /srv
echo
