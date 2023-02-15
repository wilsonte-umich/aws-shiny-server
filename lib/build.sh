# build all required Docker images
# passes all command line options to 'server build' on to 'docker compose build'
#     complete list below
#     most useful is '--no-cache' to force rebuild without using cache of intermediate images
docker compose build \
  --build-arg APPS_DIR=$APPS_DIR \
  --build-arg DATA_DIR=$DATA_DIR \
  --build-arg SERVER_DIR=$SERVER_DIR \
  --build-arg PRIVATE_DIR=$PRIVATE_DIR \
  --build-arg PACKAGE_DIR=$PACKAGE_DIR \
  --build-arg R_VERSION=$R_VERSION \
  --build-arg GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
  --build-arg GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET \
  --build-arg APP_GITHUB_REPO=$APP_GITHUB_REPO $@

# --build-arg key=val     Set build-time variables for services.
# --compress              Compress the build context using gzip.
# --force-rm              Always remove intermediate containers.
# -m, --memory MEM        Set memory limit for the build container.
# --no-cache              Do not use cache when building the image.
# --no-rm                 Do not remove intermediate containers after a successful build.
# --parallel              Build images in parallel.
# --progress string       Set type of progress output (auto, plain, tty).
# --pull                  Always attempt to pull a newer version of the image.
# -q, --quiet             Don't print anything to STDOUT
