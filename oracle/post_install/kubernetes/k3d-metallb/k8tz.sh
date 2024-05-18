#!/bin/bash

export K8TZ_DESIRED_VERSION="0.16.0"

helm repo add k8tz https://k8tz.github.io/k8tz/



# --- # --- # --- 
# --- # --- # --- 
# ---  PREPARE IMAGES FOR THE HELM CHART

# --
# - third image: the CSI registrar
# https://hub.docker.com/r/longhornio/csi-node-driver-registrar/tags?page=&page_size=&ordering=&name=arm64
export K8TZ_IMG_GUN="quay.io/k8tz/k8tz:${K8TZ_DESIRED_VERSION}-arm64"
export K8TZ_IMG_REPO_TO_DEPLOY="localhost:5001/k8tz/k8tz"
export K8TZ_IMG_TAG_TO_DEPLOY="${K8TZ_DESIRED_VERSION}-arm64"
export K8TZ_GUN_TO_DEPLOY="localhost:5001/k8tz/k8tz:${K8TZ_DESIRED_VERSION}-arm64"

docker pull --platform linux/arm64 "${K8TZ_IMG_GUN}"

docker tag "${K8TZ_IMG_GUN}" "${K8TZ_GUN_TO_DEPLOY}"

docker push "${K8TZ_GUN_TO_DEPLOY}"


# --- # --- # --- 
# --- # --- # --- 
# ---  And deploy the helm Chart




export DESIRED_DEFAULT_TIMEZONE="Europe/Paris"
kubectl create ns k8tz
helm install k8tz k8tz/k8tz \
  --set timezone=${DESIRED_DEFAULT_TIMEZONE} \
  --set image.repository=${K8TZ_IMG_REPO_TO_DEPLOY} \
  --set image.tag=${K8TZ_IMG_TAG_TO_DEPLOY} \
  -n k8tz

echo '------------------------'
echo 'kubectl get all -n k8tz'
echo '------------------------'
kubectl get all -n k8tz
figlet 'K8TZ DEPLOYED!'
echo '------------------------'
echo 'kubectl get all -n k8tz'
echo '------------------------'