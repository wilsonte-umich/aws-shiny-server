# use git to clone your Shiny app code repository
if [ "$APP_GITHUB_REPO" == "" ]; then
    echo "APP_GITHUB_REPO is not specified"
    echo "please run 'server config' first to add it"
    exit 1
else
    cd $APP_DIR
    git clone $APP_GITHUB_REPO
fi
