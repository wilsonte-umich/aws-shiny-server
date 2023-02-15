# shut down any running server by stopping its containers
docker compose \
  --env-file ../private/server-config.sh \
  down
