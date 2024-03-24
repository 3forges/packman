#!/bin/bash

sudo mkdir -p ~/minio/data
sudo docker run -d \
   -p 0.0.0.0:9000:9000 \
   -p 0.0.0.0:9001:9001 \
   --name minio \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=ROOTNAME" \
   -e "MINIO_ROOT_PASSWORD=CHANGEME123" \
   quay.io/minio/minio server /data --console-address ":9001"