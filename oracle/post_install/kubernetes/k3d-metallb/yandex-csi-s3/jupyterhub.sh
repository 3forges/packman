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

docker tag "${JUP_CUSTOM_IMG}" "localhost:5001/${JUP_CUSTOM_IMG}"
docker push "localhost:5001/${JUP_CUSTOM_IMG}"

docker rmi localhost:5001/${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}
docker rmi ${JUP_CUSTOM_IMG} --force || true

# IMPORTANT note: most of the time the
# helm times out, and just waiting a bit
# and re-running the helm upgrade is enough, so
# I think just increasing timeout or configuring
# the helm chart so that it takes time to pre-pull 
# the images before spawning the jupyterhub stack
# would do it.

export OTHER_NB_IMG_NAME="jupyter/minimal-notebook"
export OTHER_NB_IMG_TAG="latest"
export OTHER_NB_IMG_GUN="${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"
export OTHER_NB_IMG_GUN_TO_PUSH="localhost:5001/${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"

docker pull --platform linux/arm64 ${OTHER_NB_IMG_GUN}
docker tag ${OTHER_NB_IMG_GUN} ${OTHER_NB_IMG_GUN_TO_PUSH}
docker push ${OTHER_NB_IMG_GUN_TO_PUSH}

docker rmi ${OTHER_NB_IMG_GUN_TO_PUSH} --force

export OTHER_NB_IMG_NAME="jupyter/datascience-notebook"
export OTHER_NB_IMG_TAG="latest"
export OTHER_NB_IMG_GUN="${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"
export OTHER_NB_IMG_GUN_TO_PUSH="localhost:5001/${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"

docker pull --platform linux/arm64 ${OTHER_NB_IMG_GUN}
docker tag ${OTHER_NB_IMG_GUN} ${OTHER_NB_IMG_GUN_TO_PUSH}
docker push ${OTHER_NB_IMG_GUN_TO_PUSH}

docker rmi ${OTHER_NB_IMG_GUN_TO_PUSH} --force

cat <<EOF >./config.yaml
singleuser:
  image:
    name: localhost:5001/jupyter/minimal-notebook
    tag: latest
  profileList:
    - display_name: "Minimal environment"
      description: "To avoid too much bells and whistles: Python."
      default: true
    - display_name: "Décoder l'éco Data Science environment"
      description: "There you will have a notebook with R, Python, Julia."
      kubespawner_override:
        image: localhost:5001/jupyter/datascience-notebook:latest
    - display_name: "Deno/Polars Décoder l'éco environment"
      description: "There you will have a notebook with a deno (typescript) kernels available. Using Deno, you will be able to run Polars in TypeScript, https://pola-rs.github.io/nodejs-polars/."
      kubespawner_override:
        image: localhost:5001/${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}
        # c.KubeSpawner.args = '--unstable=true --notebook-dir=/home/jovyan/workspace'
        args: ' --unstable=true --notebook-dir=/home/jovyan/workspace'
        # cmd: null
        # cmd: 'jupyter lab --unstable=true --ip=0.0.0.0 --NotebookApp.base_url="\${JUPYTERHUB_SERVICE_PREFIX}" --NotebookApp.token="" --NotebookApp.password="chaillot" --notebook-dir="/home/jovyan/workspace"'
        # cmd: null
        # cmd: 'export PATH="\$HOME/.local/bin:\$PATH" && jupyter lab --unstable=true --ip=0.0.0.0 --NotebookApp.base_url="${JUPYTERHUB_SERVICE_PREFIX}" --NotebookApp.token="" --NotebookApp.password="chaillot"'
        # cmd: '/run/start.debug.sh'
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    homeMountPath: /home/jovyan/workspace
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
# ---
# For the moment, I still have the issue that the volume is mounted with root ownership on the workspace folder, so it seems i can't git clone inside workspace folder, permission denied
hub:
  podSecurityContext:
    fsGroup: 1000
    runAsUser: 1000
    runAsGroup: 1000
    fsGroupChangePolicy: "OnRootMismatch" 
EOF
# https://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html#kubespawner.KubeSpawner.container_security_context
# https://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html#kubespawner.KubeSpawner.pod_security_context
# https://z2jh.jupyter.org/en/stable/resources/reference.html#singleuser-storage-homemountpath
# https://community.ovh.com/t/pv-are-not-mounted-with-correct-permissions-inside-pods/49379/4

helm upgrade --cleanup-on-fail \
  --install decoderleco-jupyter jupyterhub/jupyterhub \
  -n decoderleco \
  --create-namespace \
  --version=3.3.7 \
  --values config.yaml

# helm delete decoderleco-jupyter -n decoderleco

kubectl get all -n decoderleco

# Ah pour le pb de permission, je pourrais peut-être utiliser un "postStart" avec un chmod comme dans https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues/1323 

exit 0

# - # # - # # - # # - # # - # # - # # - # # - #
# - #
# - # Déjà dès que je fais un docker pull de l'image ci desous il me sort un no space left on device:
# failed to register layer: write /opt/conda/libexec/gcc/aarch64-conda-linux-gnu/13.2.0/lto1: no space left on device
# - #
# - #

export OTHER_NB_IMG_NAME="jupyter/datascience-notebook"
export OTHER_NB_IMG_TAG="latest"
export OTHER_NB_IMG_GUN="${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"
export OTHER_NB_IMG_GUN_TO_PUSH="localhost:5001/${OTHER_NB_IMG_NAME}:${OTHER_NB_IMG_TAG}"

docker pull --platform linux/arm64 ${OTHER_NB_IMG_GUN}
docker tag ${OTHER_NB_IMG_GUN} ${OTHER_NB_IMG_GUN_TO_PUSH}
docker push ${OTHER_NB_IMG_GUN_TO_PUSH}


cat <<EOF >./config.yaml
singleuser:
# see https://community.ovh.com/t/pv-are-not-mounted-with-correct-permissions-inside-pods/49379/2
# >>> An init container might be the solution, yet this one does not work for now.
# $ kubectl -n decoderleco logs pod/jupyter-castafiore -c permissions-fixer
# chown: /home/jovyan: Not supported
# chmod: /home/jovyan: Not supported
  initContainers:
    - name: permissions-fixer
      image: alpine
      securityContext:
        runAsUser: 0
      volumeMounts:  # mount user persistent volume (based on volumeNameTemplate)
        # - name: volume-{username}{servername}
        - name: volume-{username}
          mountPath: /home/jovyan
      command:
        - sh
        - -c
        - (chown 1000:100 /home/jovyan; chmod 0755 /home/jovyan;)
  # Defines the default image
  image:
    name: localhost:5001/jupyter/minimal-notebook
    tag: latest
  profileList:
    - display_name: "Minimal environment"
      description: "To avoid too much bells and whistles: Python."
      default: true
    - display_name: "Décoder l'éco Data Science environment"
      description: "There you will have a notebook with R, Python, Julia."
      kubespawner_override:
        image: localhost:5001/jupyter/datascience-notebook:latest
    - display_name: "Deno/Polars Décoder l'éco environment"
      description: "There you will have a notebook with a deno (typescript) kernels available. Using Deno, you will be able to run Polars in TypeScript, https://pola-rs.github.io/nodejs-polars/."
      kubespawner_override:
        image: localhost:5001/${JUP_CUSTOM_IMG_NAME}:${JUP_CUSTOM_IMG_TAG}
        # c.KubeSpawner.args = '--unstable=true --notebook-dir=/home/jovyan/workspace'
        args: '--unstable=true --notebook-dir=/home/jovyan/workspace'
        # cmd: null
        # cmd: 'jupyter lab --unstable=true --ip=0.0.0.0 --NotebookApp.base_url="\${JUPYTERHUB_SERVICE_PREFIX}" --NotebookApp.token="" --NotebookApp.password="chaillot" --notebook-dir="/home/jovyan/workspace"'
        # cmd: null
        # cmd: 'export PATH="\$HOME/.local/bin:\$PATH" && jupyter lab --unstable=true --ip=0.0.0.0 --NotebookApp.base_url="${JUPYTERHUB_SERVICE_PREFIX}" --NotebookApp.token="" --NotebookApp.password="chaillot"'
        # cmd: '/run/start.debug.sh'
        lifecycle_hooks:
          postStart:
            exec:
              command:
                - "bash"
                - "-c"
                - >
                  # gitpuller https://github.com/decoder-leco/decoderleco_deces_europe_reloaded.git feature/kr/decoderleco/deces_europe/jupyter/rewrite /home/jovyan/deno-samples;
                  echo 'created by lifecyclehooks.postStart' > /home/jovyan/something.readme.md
                  cd /home/jovyan
                  cat <<EOF >./getSamples.sh
                  if [ -d /home/jovyan/deno-samples ]; then
                    rm -fr /home/jovyan/deno-samples
                    mkdir -p /home/jovyan/deno-samples
                  fi;
                  if [ -d /home/jovyan/workspace/deno-samples ]; then
                    rm -fr /home/jovyan/workspace/deno-samples
                    mkdir -p /home/jovyan/workspace/deno-samples
                  fi;
                  if [ -d /home/jovyan/workspace/deno-samples2 ]; then
                    rm -fr /home/jovyan/workspace/deno-samples2
                    mkdir -p /home/jovyan/workspace/deno-samples2
                  fi;
                  git clone https://github.com/decoder-leco/decoderleco_deces_europe_reloaded.git /home/jovyan/deno-samples
                  cd /home/jovyan/deno-samples
                  git checkout feature/kr/decoderleco/deces_europe/jupyter/rewrite
                  cp -fR /home/jovyan/deno-samples/* /home/jovyan/workspace/deno-samples/
                  git checkout features/R/functions/to/nodejs-polars
                  cp -fR /home/jovyan/deno-samples/* /home/jovyan/workspace/deno-samples2/
                  EOF
                  chmod +x *.sh
                  echo 'alias getSamples="/home/jovyan/getSamples.sh"' | tee -a /home/jovyan/.bashrc | tee -a /home/jovyan/.shrc
  extraEnv:
    JUPYTER_ALLOW_INSECURE_WRITES: "true"
  storage:
    homeMountPath: /home/jovyan/workspace
    capacity: 2Gi
    dynamic:
      storageClass: csi-s3
# ---
# For the moment, I still have the issue that the volume is mounted with root ownership on the workspace folder, so it seems i can't git clone inside workspace folder, permission denied
hub:
  podSecurityContext:
    fsGroup: 1000
    runAsUser: 1000
    runAsGroup: 1000
    fsGroupChangePolicy: "OnRootMismatch" 
EOF
# https://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html#kubespawner.KubeSpawner.container_security_context
# https://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html#kubespawner.KubeSpawner.pod_security_context
# https://z2jh.jupyter.org/en/stable/resources/reference.html#singleuser-storage-homemountpath
# https://community.ovh.com/t/pv-are-not-mounted-with-correct-permissions-inside-pods/49379/4