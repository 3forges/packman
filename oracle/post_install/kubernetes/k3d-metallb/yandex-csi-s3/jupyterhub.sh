#!/bin/bash

source ~/.bashrc

helm delete decoderleco-jupyter -n decoderleco || true

mkdir -p ./jupyterhub_custom/

cd ./jupyterhub_custom/

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

# okay now there a new image :
# [decoderleco/r-deno-py-jupyter:0.0.1-alpha-aarch64-hub]


# export JUP_CUSTOM_IMG="decoderleco/deno-jupyter:0.0.1-alpha-aarch64"
export JUP_CUSTOM_IMG_NAME="decoderleco/r-deno-py-jupyter"
export JUP_CUSTOM_IMG_TAG="0.0.1-alpha-aarch64-hub"

export JUP_CUSTOM_IMG="${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}"

docker tag "${JUP_CUSTOM_IMG}" "localhost:5001/${JUP_CUSTOM_IMG}"
docker push "localhost:5001/${JUP_CUSTOM_IMG}"



cat <<EOF >./config.yaml
singleuser:
  image:
    # You should replace the "latest" tag with a fixed version from:
    # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
    # Inspect the Dockerfile at:
    # https://github.com/jupyter/docker-stacks/tree/HEAD/datascience-notebook/Dockerfile
    name: localhost:5001/${JUP_CUSTOM_IMG_NAME}
    tag: ${JUP_CUSTOM_IMG_TAG}
  # 'cmd: null' allows the custom CMD of the Jupyter docker-stacks to be used
  # which performs further customization on startup.
  cmd: null
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    homeMountPath: /home/jovyan/workspace
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
EOF
# https://z2jh.jupyter.org/en/stable/resources/reference.html#singleuser-storage-homemountpath


helm upgrade --cleanup-on-fail \
  --install decoderleco-jupyter jupyterhub/jupyterhub \
  -n decoderleco \
  --create-namespace \
  --version=3.3.7 \
  --values config.yaml

# helm delete decoderleco-jupyter -n decoderleco

kubectl get all -n decoderleco


exit 0

# la custom image doit être adaptée pour jupyterhub 


cat <<EOF >./config.yaml
singleuser:
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
EOF