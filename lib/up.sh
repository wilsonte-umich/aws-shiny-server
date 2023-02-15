# launch the app server on a public web site

# enable server debug mode
DETACH="--detach"
export IS_DEBUG="FALSE"
if [ "$1" != "" ]; then
  DETACH="" # thus, docker compose shows debug app-server log in console
  export IS_DEBUG="TRUE" 
  export N_SERVER_PROCESSES=1
fi

# launch server
docker compose \
  --env-file ../private/server-config.sh \
  up \
    --scale app-server=$N_SERVER_PROCESSES \
    --remove-orphans \
    $DETACH
