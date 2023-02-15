# use an ephemeral app-server container to install the app
docker compose run \
  --no-deps \
  --rm \
  app-server bash install-everything.sh
