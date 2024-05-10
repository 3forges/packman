#!/bin/bash

export KND_NET_NAME="kind"

figlet 'Spinup Troubleshooter'

source ./.troubleshooter.env.sh
docker-compose -f ./troubleshooter.yml build
docker-compose -f ./troubleshooter.yml up -d

docker network connect ${KND_NET_NAME} k3d_net_plumber

docker inspect k3d_net_plumber -f "{{json .NetworkSettings.Networks }}" | jq .${KND_NET_NAME}