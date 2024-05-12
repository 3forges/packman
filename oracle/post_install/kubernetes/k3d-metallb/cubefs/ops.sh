#!/bin/bash

sudo mkdir -p /cubefs_data/disk
sudo chown $USER: -R /cubefs_data

git clone https://github.com/cubefs/cubefs.git ./cubefs_decoderleco/
cd ./cubefs_decoderleco/

chmod +x ./docker/run_docker.sh

figlet 'CUBEFS STARTUP SCRIPT HELP'

./docker/run_docker.sh -h



figlet 'LAUNCH CUBEFS STARTUP'

# ./docker/run_docker.sh -r -d /cubefs_data/disk
figlet 'CUBEFS build from source'
./docker/run_docker.sh -b
figlet 'CUBEFS start server docker images'
./docker/run_docker.sh -s -d /cubefs_data/disk
figlet 'CUBEFS start client docker image'
./docker/run_docker.sh -c
figlet 'CUBEFS start monitor web ui'
./docker/run_docker.sh -m

# -------------------------------------------------------
# After the client is started, use the mount command in
# the client docker container to check the 
# directory mounting status:

mount | grep cubefs


# Open http://127.0.0.1:3000 in a browser, log in with admin/123456, and you can view the Grafana monitoring indicator interface of CubeFS.

figlet 'CUBEFS CLUSTER UP!'

echo 'Open http://127.0.0.1:3000 in a browser'
echo 'log in with admin/123456'
echo 'and you can view the Grafana monitoring'
echo 'indicator interface of CubeFS'
