# use git to clone a single Shiny app code repository
if [ "$APP_GITHUB_REPO" == "" ]; then
    echo "APP_GITHUB_REPO is not specified"
    echo "please run 'server config' first to add it"
    echo "if your server will run multiple apps, you must install them manually into:"
    ehco "   /srv/apps/<YOUR_APP_NAME>"
    exit 1
else
    cd $APPS_DIR
    git clone $APP_GITHUB_REPO
fi
