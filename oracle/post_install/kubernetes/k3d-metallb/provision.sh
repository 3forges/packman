#!/bin/bash

sudo mkdir -p /usr/local/bin/

sudo apt-get install -y jq figlet


# 1./ Install arkade
figlet 'Install arkade'

curl -sLS https://get.arkade.dev | sudo sh

arkade version


# 2./ Install k3d

figlet 'Install k3d'
arkade get k3d

sudo mv ${HOME}/.arkade/bin/k3d /usr/local/bin/


# 2./ Install kubectl and helm

figlet 'Install kubectl'

arkade get kubectl

sudo mv ${HOME}/.arkade/bin/kubectl /usr/local/bin/

kubectl version --client


figlet 'Install helm'

arkade get helm

sudo mv ${HOME}/.arkade/bin/helm /usr/local/bin/

helm version
# version.BuildInfo{Version:"v3.14.4", GitCommit:"81c902a123462fd4052bc5e9aa9c513c4c8fc142", GitTreeState:"clean", GoVersion:"go1.21.9"}

# 4./ create k3d kubernetes cluster

figlet 'create k3d kubernetes cluster'
# ---
# K3D_NET_NAME: the name of the docker network used by the k3d cluster
export K3D_NET_NAME="decoderleco_knet"
docker network create ${K3D_NET_NAME}

k3d cluster create k8-lab --network "${K3D_NET_NAME}" --api-port 6550 --agents 1 --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait


kubectl cluster-info

# 5./ deploy metallb


figlet 'deploy metallb'
export METALLB_K8S_NAMESPACE="metallb-system"
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/namespace.yaml
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml


figlet 'get helm chart'

## 5.a) Get the Bitnami helm Chart and set the Metallb desired configuration directly into the [./templates/controller/configmap.yaml] Helm template file

# https://github.com/bitnami/charts/tree/main/bitnami/metallb/#installing-the-chart

# git clone https://github.com/bitnami/charts ./bitnamischarts
export DESIRED_VERSION=136846926733d172c3d52646e1576188839a063e
export DESIRED_BRANCH=main
export BITNAMI_CHARTS_REPO_URL=https://github.com/bitnami/charts
git clone -b ${DESIRED_BRANCH} --depth 1  --single-branch ${BITNAMI_CHARTS_REPO_URL} ./bitnamischarts

cd ./bitnamischarts

git checkout ${DESIRED_VERSION} || true
# The version i tested which shouldbe desired:
# $ git rev-parse --short=40 HEAD
# 136846926733d172c3d52646e1576188839a063e

cd bitnami/metallb


figlet 'Metallb config'

export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')

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
      - $K3D_NET_RANGE
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
kubectl delete -f ./nginx-deployment.yaml

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
