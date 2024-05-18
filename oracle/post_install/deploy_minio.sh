#!/bin/bash

source ~/.bashrc

export MINIO_ROOT_USER=${MINIO_CSI_DRIVER_ROOT_USER:-"ROOTNAME"}
export MINIO_ROOT_PASSWORD=${MINIO_CSI_DRIVER_ROOT_PASSWORD:-"CHANGEME123"}
# ---
# This minio will be used by Kubernetes CSI DRIVER 
# [oracle/post_install/kubernetes/k3d-metallb/yandex-csi-s3/arm64.sh]
# --- 
sudo apt-get install -y figlet
figlet 'Deploy Minio'

echo "MINIO_ROOT_USER=[$MINIO_ROOT_USER]"
# echo "MINIO_ROOT_PASSWORD=[$MINIO_ROOT_PASSWORD]"

sudo docker stop minio || true
sudo docker rm minio || true

if [ -d ~/minio/data ]; then
  sudo rm -fr ~/minio/data
fi;


sudo mkdir -p ~/minio/data
sudo docker run -d \
   -p 0.0.0.0:9000:9000 \
   -p 0.0.0.0:9001:9001 \
   --name minio \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER='${MINIO_ROOT_USER}'" \
   -e "MINIO_ROOT_PASSWORD='${MINIO_ROOT_PASSWORD}'" \
   quay.io/minio/minio server /data --console-address ":9001"