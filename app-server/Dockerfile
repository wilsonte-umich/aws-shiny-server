# use a specific R version
ARG R_VERSION
FROM r-base:$R_VERSION

# suppress a docker compose build warning that build-args R_VERSION was not consumed
ARG R_VERSION

# prepare the system to install R packages
# include some useful tools for developer use
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libmariadb-dev \
    zlib1g-dev \
    libxml2 \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libx11-dev \
    libgit2-dev \
    libssh2-1-dev \
    pkg-config \
    build-essential \
    git \
    wget \
    zip \
    time \
    nano \
    tree \
    curl

# hard set installation directory in image
ARG APPS_DIR
ENV APPS_DIR=$APPS_DIR
ARG DATA_DIR
ENV DATA_DIR=$DATA_DIR
ARG SERVER_DIR
ENV SERVER_DIR=$SERVER_DIR
ARG PRIVATE_DIR
ENV PRIVATE_DIR=$PRIVATE_DIR
ARG PACKAGE_DIR
ENV PACKAGE_DIR=$PACKAGE_DIR
ARG APP_GITHUB_REPO
ENV APP_GITHUB_REPO=$APP_GITHUB_REPO
ARG GOOGLE_CLIENT_ID
ENV GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
ARG GOOGLE_CLIENT_SECRET
ENV GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET

# install server management tools in /srv/tools
# the image launches in this directory
ENV TOOLS_DIR=/srv/tools
WORKDIR $TOOLS_DIR

# add scripts to install, update and modify the app
COPY ./install-everything.sh $TOOLS_DIR/install-everything.sh
COPY ./install-packages.R    $TOOLS_DIR/install-packages.R
COPY ./start-app-server.R    $TOOLS_DIR/start-app-server.R
COPY ./ui.R                  $TOOLS_DIR/ui.R
COPY ./server.R              $TOOLS_DIR/server.R
COPY ./authentication.R      $TOOLS_DIR/authentication.R
COPY ./server.js             $TOOLS_DIR/www/server.js

# if this image is run as a container manually, just provide a command line
# start-app-server.R is called via 'command' in docker-compose.yml
CMD ["/bin/bash"]
