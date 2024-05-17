#!/bin/bash



mkdir -p ./jupyterhub_custom/

cd ./jupyterhub_custom/

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

export JUP_CUSTOM_IMG="decoderleco/deno-jupyter:0.0.1-alpha-aarch64"
docker tag "${JUP_CUSTOM_IMG}" "localhost:5001/${JUP_CUSTOM_IMG}"
docker push "localhost:5001/${JUP_CUSTOM_IMG}"

cat <<EOF >./config.yaml
singleuser:
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
EOF

helm upgrade --cleanup-on-fail \
  --install decoderleco-jupyter jupyterhub/jupyterhub \
  --namespace decoderleco \
  --create-namespace \
  --version=3.3.7 \
  --values config.yaml

# helm delete decoderleco-jupyter --namespace decoderleco

kubectl get all -n decoderleco


exit 0

# la custom image doit être adaptée pour jupyterhub 


cat <<EOF >./config.yaml
singleuser:
  image:
    # You should replace the "latest" tag with a fixed version from:
    # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
    # Inspect the Dockerfile at:
    # https://github.com/jupyter/docker-stacks/tree/HEAD/datascience-notebook/Dockerfile
    name: localhost:5001/decoderleco/deno-jupyter
    tag: 0.0.1-alpha-aarch64
  # 'cmd: null' allows the custom CMD of the Jupyter docker-stacks to be used
  # which performs further customization on startup.
  cmd: null
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
EOF
