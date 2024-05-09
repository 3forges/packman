#!/bin/bash

export K3D_NET_NAME="decoderleco_knet"

figlet 'Spinup Troubleshooter'

source ./.troubleshooter.env.sh
docker-compose -f ./troubleshooter.yml build
docker-compose -f ./troubleshooter.yml up -d

docker network connect ${K3D_NET_NAME} k3d_net_plumber

docker inspect k3d_net_plumber -f "{{json .NetworkSettings.Networks }}" | jq .${K3D_NET_NAME}