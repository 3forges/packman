#!/bin/bash



mkdir -p ./jupyterhub_custom/

cd ./jupyterhub_custom/

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

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

