# this script runs in an app-server container to install the app's packages
# into the persistent docker volume known to all such containers

# set the number of cores for parallel R package compilation
export N_CPU=`nproc`

# install the app's R packages
Rscript install-packages.R

# remove R package tarballs to control image/container size
rm -f /tmp/Rtmp*/downloaded_packages/*.tar.gz
