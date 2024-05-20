#!/bin/bash

source ~/.bashrc

helm delete decoderleco-jupyter -n decoderleco || true

mkdir -p ./jupyterhub_custom/

cd ./jupyterhub_custom/

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

# okay now there a new image :
# [decoderleco/r-deno-py-jupyter:0.0.1-alpha-aarch64-hub]

helm delete decoderleco-jupyter -n decoderleco || true

# export JUP_CUSTOM_IMG="decoderleco/deno-jupyter:0.0.1-alpha-aarch64"
export JUP_CUSTOM_IMG_NAME="decoderleco/r-deno-py-jupyter"
export JUP_CUSTOM_IMG_TAG="0.0.1-alpha-aarch64-hub"

export JUP_CUSTOM_IMG="${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}"

docker tag "${JUP_CUSTOM_IMG}" "localhost:5001/${JUP_CUSTOM_IMG}-2"
docker push "localhost:5001/${JUP_CUSTOM_IMG}-2"



cat <<EOF >./config.yaml
singleuser:
  # Defines the default image
  image:
    name: jupyter/minimal-notebook
    tag: 2343e33dec46
  profileList:
    - display_name: "Minimal environment"
      description: "To avoid too much bells and whistles: Python."
      default: true
    - display_name: "Python/R/Deno/Polars Décoder l'éco environment"
      description: "There you will have a notebook with several kernels available, among which you will have the Deno/Polars specific environment."
      kubespawner_override:
        image: localhost:5001/${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}-2
        # c.KubeSpawner.args = '--unstable=true --notebook-dir=/home/jovyan/workspace'
        args: '--unstable=true --notebook-dir=/home/jovyan/workspace'
    - display_name: "Datascience environment"
      description: "If you want the additional bells and whistles: Python, R, and Julia."
      kubespawner_override:
        image: jupyter/datascience-notebook:2343e33dec46
    - display_name: "Spark environment"
      description: "The Jupyter Stacks spark image!"
      kubespawner_override:
        image: jupyter/all-spark-notebook:2343e33dec46
    - display_name: "Learning Data Science"
      description: "Datascience Environment with Sample Notebooks"
#       kubespawner_override:
        image: jupyter/datascience-notebook:2343e33dec46
        lifecycle_hooks:
          postStart:
            exec:
              command:
                - "sh"
                - "-c"
                - >
                  gitpuller https://github.com/data-8/materials-fa17 master materials-fa;
  # image:
  #   # You should replace the "latest" tag with a fixed version from:
  #   # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
  #   # Inspect the Dockerfile at:
  #   # https://github.com/jupyter/docker-stacks/tree/HEAD/datascience-notebook/Dockerfile
  #   name: localhost:5001/${JUP_CUSTOM_IMG_NAME}
  #   tag: ${JUP_CUSTOM_IMG_TAG}-2
  # 'cmd: null' allows the custom CMD of the Jupyter docker-stacks to be used
  # which performs further customization on startup.
  # cmd: null
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    homeMountPath: /home/jovyan/workspace
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3

# # https://z2jh.jupyter.org/en/latest/resources/reference.html#hub-extraconfig
# hub:
#   extraConfig:
#     myConfig.py: |
      # c.Spawner.args = '--unstable=true --notebook-dir=/home/jovyan/workspace'
      # # c.Spawner.notebook_dir = '/home/jovyan/workspace'
      # # c.KubeSpawner.args = '--unstable=true --notebook-dir=/home/jovyan/workspace'
      # # c.KubeSpawner.notebook_dir = '/home/jovyan/workspace'
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


