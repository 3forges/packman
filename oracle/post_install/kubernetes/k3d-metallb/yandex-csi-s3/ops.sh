#!/bin/bash

export minio_container_name="minio"
# export MINIO_BUCKET_URL="http://${minio_container_name}:9000/juicefs"
export MINIO_ENDPOINT="http://${minio_container_name}:9000"
export MINIO_ACCESS_KEY="f7a5aJLswKEwYcmZAGXW"
export MINIO_SECRET_KEY="P6KujEDBpEoud9oBwHHGzCdzSEAm3P1TxZnzARtT"
docker network connect "kind" "${minio_container_name}"



helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts


helm install csi-s3 yandex-s3/csi-s3 \
     -n kube-system \
     --set secret.accessKey=${MINIO_ACCESS_KEY} \
     --set secret.secretKey=${MINIO_SECRET_KEY} \
     --set secret.endpoint=${MINIO_ENDPOINT}

helm delete csi-s3 -n kube-system

