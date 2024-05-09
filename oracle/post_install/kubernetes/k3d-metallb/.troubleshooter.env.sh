#!/bin/bash

export K3D_NET_NAME=${K3D_NET_NAME:-"decoderleco_knet"}
export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')
export K3D_NET_BASE_ADDR=${K3D_NET_CIDR_BLOCK%???}
export K3D_NET_FIRST_ADDR=$(echo $K3D_NET_CIDR_BLOCK | awk -F'.' '{print $1,$2,$3,240}' OFS='.')
export K3D_NET_RANGE="$K3D_NET_FIRST_ADDR/29"


echo "K3D_NET_NAME=[${K3D_NET_NAME}]"
echo "K3D_NET_CIDR_BLOCK=[${K3D_NET_CIDR_BLOCK}]"
echo "K3D_NET_BASE_ADDR=[${K3D_NET_BASE_ADDR}]"
echo "K3D_NET_FIRST_ADDR=[${K3D_NET_FIRST_ADDR}]"
echo "K3D_NET_RANGE=[${K3D_NET_RANGE}]"


# export K3D_NET_FIRST_ADDR=${K3D_NET_FIRST_ADDR:-'172.19.0.240'}
# export K3D_NET_RANGE=${K3D_NET_RANGE:-'172.19.0.240/29'}