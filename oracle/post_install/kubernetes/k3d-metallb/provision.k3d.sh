#!/bin/bash
set -o errexit

sudo mkdir -p /usr/local/bin/

sudo apt-get install -y jq figlet


# 1./ Install arkade
figlet 'Install arkade'

curl -sLS https://get.arkade.dev | sudo sh

arkade version


# 2./ Install k3d

figlet 'Install k3d'


if ! [ -f /usr/local/bin/k3d ]; then
  arkade get k3d
  sudo mv ${HOME}/.arkade/bin/k3d /usr/local/bin/
else
  figlet 'k3d already installed'
  ls -alh /usr/local/bin/k3d
fi;

k3d version

# 2./ Install kubectl and helm

figlet 'Install kubectl'

if ! [ -f /usr/local/bin/kubectl ]; then
  arkade get kubectl
  sudo mv ${HOME}/.arkade/bin/kubectl /usr/local/bin/
else
  figlet 'kubectl already installed'
  ls -alh /usr/local/bin/kubectl
fi;


kubectl version --client


figlet 'Install helm'

if ! [ -f /usr/local/bin/helm ]; then
  arkade get helm
  sudo mv ${HOME}/.arkade/bin/helm /usr/local/bin/
else
  figlet 'helm already installed'
  ls -alh /usr/local/bin/helm
fi;


helm version
# version.BuildInfo{Version:"v3.14.4", GitCommit:"81c902a123462fd4052bc5e9aa9c513c4c8fc142", GitTreeState:"clean", GoVersion:"go1.21.9"}

# 3./ create local docker registry

# ---
# K3D_NET_NAME: the name of the docker network 
# used by the k3d cluster.
export K3D_NET_NAME="decoderleco_knet"
docker network create ${K3D_NET_NAME} || true

sudo mkdir -p /etc/containerd/certs.d

# 3.a.- Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
docker stop ${reg_name} || true
docker rm ${reg_name} || true
reg_name='k3d-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
    registry:2
fi

# 3.b.- Add the registry config to the nodes
#
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${reg_port} to the registry container when pulling images
# REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
# for node in $(kind get nodes -n ${KNB_CLUSTER_NAME}); do
#   docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
#   cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
# [host."http://${reg_name}:5000"]
# EOF
# done

# 3.c.-  Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f=\"{{json .NetworkSettings.Networks.$K3D_NET_NAME}}\" "${reg_name}")" = 'null' ]; then
  docker network connect "${K3D_NET_NAME}" "${reg_name}"
fi




cat <<EOF >./local-registry-config.yaml
mirrors:
  "${reg_name}:${reg_port}":
    endpoint:
      - http://${reg_name}:${reg_port}
EOF


# 4.a./ create k3d kubernetes cluster

figlet 'create k3d kubernetes cluster'
export K3D_CLUSTER_NAME="k8-lab-decoderleco"

k3d cluster delete ${K3D_CLUSTER_NAME} || true
# k3d cluster delete --all || true

# k3d cluster create ${K3D_CLUSTER_NAME} --registry-config ./local-registry-config.yaml --network "${K3D_NET_NAME}" --api-port 6550 --agents 1 --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait
k3d cluster create ${K3D_CLUSTER_NAME} --network "${K3D_NET_NAME}" --api-port 6550 --agents 1 --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait

sleep 60s

kubectl cluster-info


# 4.b./- Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://k3d.io/v5.2.0/usage/registries/#registries-configuration-file"
EOF

# 5./ Test cluster + registry
figlet 'Test cluster + registry'
# docker pull arm64v8/hello-world
docker pull --platform linux/arm64 traefik/whoami:v1.10
# docker pull gcr.io/google-samples/hello-app:1.0
# ubuntu@myserver:~$ docker pull --platform linux/arm64 nginx
# Using default tag: latest
# latest: Pulling from library/nginx
# 22d97f6a5d13: Already exists
# a68473e9d216: Pull complete
# 7c0a9e5032ac: Pull complete
# 43f7d7c8e1e1: Pull complete
# a23342af148c: Pull complete
# 18b7abeaeadc: Pull complete
# 568b5ecc128d: Pull complete
# Digest: sha256:32e76d4f34f80e479964a0fbd4c5b4f6967b5322c8d004e9cf0cb81c93510766
# Status: Downloaded newer image for nginx:latest
# docker.io/library/nginx:latest
# ubuntu@myserver:~$ docker pull --platform linux/arm64 gcr.io/google-samples/hello-app:1.0
# 1.0: Pulling from google-samples/hello-app
# Digest: sha256:b1455e1c4fcc5ea1023c9e3b584cd84b64eb920e332feff690a2829696e379e7
# Status: Image is up to date for gcr.io/google-samples/hello-app:1.0
# image with reference gcr.io/google-samples/hello-app:1.0 was found but does not match the specified platform: wanted linux/arm64, actual: linux/amd64



# docker tag arm64v8/hello-world localhost:5001/arm64v8/hello-world:0.1
docker tag traefik/whoami:v1.10 localhost:5001/traefik/whoami:v1.10

docker push localhost:5001/traefik/whoami:v1.10

kubectl create deployment hello-server --image=localhost:5001/traefik/whoami:v1.10

kubectl get all


# 6./ deploy metallb
sleep 5s


figlet 'deploy metallb'
export METALLB_K8S_NAMESPACE="metallb-system"
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
kubectl create ns ${METALLB_K8S_NAMESPACE}

helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n ${METALLB_K8S_NAMESPACE}
# helm delete metallb -n ${METALLB_K8S_NAMESPACE}


# Then we wait something like 1 or 2 minutes to let the Metallb deployment get up n running cosily, because of issues like https://github.com/metallb/metallb/issues/1540
sleep 120s

figlet 'Metallb config'
export K3D_NET_NAME="decoderleco_knet"
# export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')
export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[1].Subnet' | tr -d '"')

echo "K3D_NET_CIDR_BLOCK=[${K3D_NET_CIDR_BLOCK}]"

export K3D_NET_BASE_ADDR=${K3D_NET_CIDR_BLOCK%???}

export K3D_NET_FIRST_ADDR=$(echo $K3D_NET_CIDR_BLOCK | awk -F'.' '{print $1,$2,$3,240}' OFS='.')

export K3D_NET_RANGE="$K3D_NET_FIRST_ADDR/29"


echo "K3D_NET_BASE_ADDR=[${K3D_NET_BASE_ADDR}]"
echo "K3D_NET_FIRST_ADDR=[${K3D_NET_FIRST_ADDR}]"
echo "K3D_NET_RANGE=[${K3D_NET_RANGE}]"

# e.g. output :
#  K3D_NET_CIDR_BLOCK=[172.19.0.0/16]
#  K3D_NET_BASE_ADDR=[172.19.0.0]
#  K3D_NET_FIRST_ADDR=[172.19.0.240]
#  K3D_NET_RANGE=[172.19.0.240/29]
export METALLB_ADDR_POOL_NAME="decoderleco-pool"
cat <<EOF >./metallb-address-pool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ${METALLB_ADDR_POOL_NAME}
  namespace: ${METALLB_K8S_NAMESPACE}
spec:
  addresses:
  - $K3D_NET_RANGE
EOF

kubectl apply -f ./metallb-address-pool.yaml


cat <<EOF >./metallb-L2Advertisement.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: decoderleco
  namespace: ${METALLB_K8S_NAMESPACE}
spec:
  ipAddressPools:
  - ${METALLB_ADDR_POOL_NAME}
EOF
kubectl apply -f ./metallb-L2Advertisement.yaml



# ---
# 7./ DEPLOY NGINX TO TEST IF NGINX GETS AN EXTERNAL IP in the k3d docker network

figlet 'DEPLOY NGINX'

cat <<EOF >./nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx  
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: nginx
EOF

kubectl apply -f ./nginx-deployment.yaml
# kubectl delete -f ./nginx-deployment.yaml

# --- 
#
# with kubectk i should get something like:
# 
#   nginx                      LoadBalancer   10.43.223.116   172.18.0.242   80:32017/TCP                  17s
# 
# --- 
# 




exit 0


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${METALLB_K8S_NAMESPACE}
  name: ${HELM_MLB_RELEASE_NAME}-config
  labels:
    app.kubernetes.io/instance: metallb-decoderleco
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: metallb
    app.kubernetes.io/version: 0.14.5
    helm.sh/chart: metallb-6.1.4
  annotations:
    meta.helm.sh/release-name: metallb-decoderleco
    meta.helm.sh/release-namespace: ${METALLB_K8S_NAMESPACE}
    kubectl.kubernetes.io: last-applied-configuration
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $K3D_NET_RANGE
EOF
# kubectl delete cm/${HELM_MLB_RELEASE_NAME}-config -n ${METALLB_K8S_NAMESPACE}

# kubectl get all -n ${METALLB_K8S_NAMESPACE}
# kubectl describe cm -n ${METALLB_K8S_NAMESPACE}
# kubectl get cm -n ${METALLB_K8S_NAMESPACE}
