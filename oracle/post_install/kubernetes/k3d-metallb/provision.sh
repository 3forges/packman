#!/bin/bash
set -o errexit

sudo mkdir -p /usr/local/bin/

sudo apt-get install -y jq figlet


# 1./ Install arkade
figlet 'Install arkade'

curl -sLS https://get.arkade.dev | sudo sh

arkade version


# 2./ Install kind

figlet 'Install kind'


if ! [ -f /usr/local/bin/kind ]; then
  arkade get kind
  sudo mv ${HOME}/.arkade/bin/kind /usr/local/bin/
else
  figlet 'king already installed'
fi;

kind version

# 2./ Install kubectl and helm

figlet 'Install kubectl'

if ! [ -f /usr/local/bin/kind ]; then
  arkade get kubectl
  sudo mv ${HOME}/.arkade/bin/kubectl /usr/local/bin/
else
  figlet 'kubectl already installed'
fi;


kubectl version --client


figlet 'Install helm'

if ! [ -f /usr/local/bin/helm ]; then
  arkade get helm
  sudo mv ${HOME}/.arkade/bin/helm /usr/local/bin/
else
  figlet 'helm already installed'
fi;


helm version
# version.BuildInfo{Version:"v3.14.4", GitCommit:"81c902a123462fd4052bc5e9aa9c513c4c8fc142", GitTreeState:"clean", GoVersion:"go1.21.9"}

# 4./ create kind kubernetes cluster, with a local docker registry

figlet 'create kind kubernetes cluster'
# ---
# KND_NET_NAME: the name of the docker network used by the kind cluster
export KND_NET_NAME="decoderleco_knet"
export KND_NET_NAME="kind"
# docker network create ${KND_NET_NAME}

# kind create cluster -n k8-lab-decoderleco --wait 3m

sudo mkdir -p /etc/containerd/certs.d

# 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
    registry:2
fi

kind delete clusters --all
# 2. Create kind cluster with containerd registry config dir enabled
# TODO: kind will eventually enable this by default and this patch will
# be unnecessary.
#
# See:
# https://github.com/kubernetes-sigs/kind/issues/2875
# https://github.com/containerd/containerd/blob/main/docs/cri/config.md#registry-configuration
# See: https://github.com/containerd/containerd/blob/main/docs/hosts.md
cat <<EOF | kind create cluster -n k8-lab-decoderleco --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF

# 3. Add the registry config to the nodes
#
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${reg_port} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# 4. Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 5. Document the local registry
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
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

kubectl cluster-info

figlet 'Test cluster + registry'

docker pull gcr.io/google-samples/hello-app:1.0

docker tag gcr.io/google-samples/hello-app:1.0 localhost:5001/hello-app:1.0

docker push localhost:5001/hello-app:1.0

kubectl create deployment hello-server --image=localhost:5001/hello-app:1.0


kubectl get all






















# 5./ deploy metallb


figlet 'deploy metallb'
export METALLB_K8S_NAMESPACE="metallb-system"
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml


helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system




figlet 'Metallb config'
export KND_NET_NAME="kind"
export KND_NET_CIDR_BLOCK=$(docker network inspect ${KND_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')

echo "KND_NET_CIDR_BLOCK=[${KND_NET_CIDR_BLOCK}]"

export KND_NET_BASE_ADDR=${KND_NET_CIDR_BLOCK%???}

export KND_NET_FIRST_ADDR=$(echo $KND_NET_CIDR_BLOCK | awk -F'.' '{print $1,$2,$3,240}' OFS='.')

export KND_NET_RANGE="$KND_NET_FIRST_ADDR/29"


echo "KND_NET_BASE_ADDR=[${KND_NET_BASE_ADDR}]"
echo "KND_NET_FIRST_ADDR=[${KND_NET_FIRST_ADDR}]"
echo "KND_NET_RANGE=[${KND_NET_RANGE}]"

# e.g. output :
#  KND_NET_CIDR_BLOCK=[172.19.0.0/16]
#  KND_NET_BASE_ADDR=[172.19.0.0]
#  KND_NET_FIRST_ADDR=[172.19.0.240]
#  KND_NET_RANGE=[172.19.0.240/29]
export METALLB_ADDR_POOL_NAME="decoderleco-pool"
cat <<EOF >./metallb-address-pool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ${METALLB_ADDR_POOL_NAME}
  namespace: metallb-system
spec:
  addresses:
  - $KND_NET_RANGE
EOF

kubectl apply -f ./metallb-address-pool.yaml


cat <<EOF >./metallb-L2Advertisement.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: decoderleco
  namespace: metallb-system
spec:
  ipAddressPools:
  - ${METALLB_ADDR_POOL_NAME}
EOF
kubectl apply -f ./metallb-L2Advertisement.yaml



# ---
# 6./ DEPLOY NGINX TO TEST IF NGINX GETS AN EXTERNAL IP in the k3d docker network

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


ls -alh ./templates/controller/configmap.yaml
cat <<EOF >./templates/controller/configmap.yaml
{{- /*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- if not .Values.existingConfigMap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "metallb.configMapName" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- include "common.labels.standard" ( dict "customLabels" .Values.commonLabels "context" \$ ) | nindent 4 }}
  {{- if .Values.commonAnnotations }}
  annotations: {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" \$ ) | nindent 4 }}
  {{- end }}
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $KND_NET_RANGE
{{- end -}}
EOF



## 5.b) deploy metallb bitnamis helm chart


figlet 'Deploy Metallb  with Helm'


# now we need to deploy our helm charts using the appropriate values.yaml
helm dependency build
export HELM_MLB_RELEASE_NAME="metallb-decoderleco"
# helm install -f ./values.yaml ${HELM_MLB_RELEASE_NAME} ./
# helm delete ${HELM_MLB_RELEASE_NAME}

kubectl create ns ${METALLB_K8S_NAMESPACE}
helm install -n ${METALLB_K8S_NAMESPACE} -f ./values.yaml ${HELM_MLB_RELEASE_NAME} ./
# helm delete ${HELM_MLB_RELEASE_NAME} -n ${METALLB_K8S_NAMESPACE}

# kubectl get all -n ${METALLB_K8S_NAMESPACE}
# kubectl describe cm -n ${METALLB_K8S_NAMESPACE}
# kubectl get cm -n ${METALLB_K8S_NAMESPACE}







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
      - $KND_NET_RANGE
EOF
# kubectl delete cm/${HELM_MLB_RELEASE_NAME}-config -n ${METALLB_K8S_NAMESPACE}

# kubectl get all -n ${METALLB_K8S_NAMESPACE}
# kubectl describe cm -n ${METALLB_K8S_NAMESPACE}
# kubectl get cm -n ${METALLB_K8S_NAMESPACE}
