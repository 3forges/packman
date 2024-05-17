#!/bin/bash

# --- # --- # --- # --- 
# --- # --- # --- # --- 
# Install GOLANG
# --- # --- # --- # --- 
# --- # --- # --- # --- 

export GOLANG_TAR="https://go.dev/dl/go1.22.3.linux-arm64.tar.gz"
curl -LO ${GOLANG_TAR}
ls -alh ./go1.22.3.linux-arm64.tar.gz
rm -rf /usr/local/go || true
sudo tar -C /usr/local -xzf ./go1.22.3.linux-arm64.tar.gz
export PATH=$PATH:/usr/local/go/bin

echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc

go version
# --- # --- # --- # --- 
# --- # --- # --- # --- 
# --- BUILD IT
# --- # --- # --- # --- 
# --- # --- # --- # --- 
git clone https://github.com/motoki317/k8s-csi-s3.git ./k8s-csi-s3-arm64
cd ./k8s-csi-s3-arm64
git checkout build-linux-arm64

make build

make container



# --- # --- # --- 
# --- # --- # --- 
# ---  PREPARE IMAGES FOR THE HELM CHART

# --
# - first image: the CSI driver i re-built
export REBUILT_CSI_DRIVER_IMG_NAME=$(docker images | grep yandex | awk '{ print $1 }')
export REBUILT_CSI_DRIVER_IMG_TAG=$(docker images | grep yandex | awk '{ print $2 }')
export REBUILT_CSI_DRIVER_GUN="${REBUILT_CSI_DRIVER_IMG_NAME}:${REBUILT_CSI_DRIVER_IMG_TAG}"

echo "REBUILT_CSI_DRIVER_GUN=[${REBUILT_CSI_DRIVER_GUN}]"

export CSI_DRIVER_GUN_TO_DEPLOY="localhost:5001/${REBUILT_CSI_DRIVER_GUN}-arm64"

docker tag "${REBUILT_CSI_DRIVER_GUN}" "${CSI_DRIVER_GUN_TO_DEPLOY}"

docker push "${CSI_DRIVER_GUN_TO_DEPLOY}"

# --
# - second image: the CSI provisioner
# ok not easy to find one for arm64, so i try that one found randomly on dockerhub
export PROVISIONER_IMG_GUN="kunde21/k8s-provisioner:v2.2.0-arm64"
export CSI_PROVISIONER_GUN_TO_DEPLOY="localhost:5001/csi-s3/csi-provisioner:v2.2.0-arm64"

docker pull --platform linux/arm64 "${PROVISIONER_IMG_GUN}"

docker tag "${PROVISIONER_IMG_GUN}" "${CSI_PROVISIONER_GUN_TO_DEPLOY}"

docker push "${CSI_PROVISIONER_GUN_TO_DEPLOY}"


# --
# - third image: the CSI registrar
# https://hub.docker.com/r/longhornio/csi-node-driver-registrar/tags?page=&page_size=&ordering=&name=arm64
export REGISTRAR_IMG_GUN="longhornio/csi-node-driver-registrar:v2.3.0-arm64"
export CSI_REGISTRAR_GUN_TO_DEPLOY="localhost:5001/csi-s3/csi-node-driver-registrar:v2.3.0-arm64"

docker pull --platform linux/arm64 "${REGISTRAR_IMG_GUN}"

docker tag "${REGISTRAR_IMG_GUN}" "${CSI_REGISTRAR_GUN_TO_DEPLOY}"

docker push "${CSI_REGISTRAR_GUN_TO_DEPLOY}"


# --- # --- # --- 
# --- # --- # --- 
# ---  And re-deploy the helm Chart












export minio_container_name="minio"
# export MINIO_BUCKET_URL="http://${minio_container_name}:9000/juicefs"
export MINIO_ENDPOINT="http://${minio_container_name}:9000"
export MINIO_ACCESS_KEY="f7a5aJLswKEwYcmZAGXW"
export MINIO_SECRET_KEY="P6KujEDBpEoud9oBwHHGzCdzSEAm3P1TxZnzARtT"
docker network connect "kind" "${minio_container_name}"



helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts

helm delete csi-s3 -n kube-system || true

helm install csi-s3 yandex-s3/csi-s3 \
     -n kube-system \
     --set secret.accessKey=${MINIO_ACCESS_KEY} \
     --set secret.secretKey=${MINIO_SECRET_KEY} \
     --set secret.endpoint=${MINIO_ENDPOINT} \
     --set images.provisioner=${CSI_PROVISIONER_GUN_TO_DEPLOY} \
     --set images.csi=${CSI_DRIVER_GUN_TO_DEPLOY} \
     --set images.registrar=${CSI_REGISTRAR_GUN_TO_DEPLOY}



figlet 'Test now'

kubectl get all -n kube-system --selector=app=csi-s3-provisioner
kubectl logs service/csi-s3-provisioner -n kube-system
kubectl describe pod/csi-s3-provisioner-0 -n kube-system
kubectl describe service/csi-s3-provisioner -n kube-system


kubectl create ns test2
mkdir -p test2/
cat <<EOF >./test2/pvc.yaml
# Dynamically provisioned PVC:
# A bucket or path inside bucket will be created automatically
# for the PV and removed when the PV will be removed
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-s3-pvc
  namespace: test2
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: csi-s3
EOF

cat <<EOF >./test2/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: csi-s3-test-nginx
  namespace: test2
spec:
  containers:
   - name: csi-s3-test-nginx
     image: nginx
     volumeMounts:
       - mountPath: /usr/share/nginx/html/s3
         name: webroot
  volumes:
   - name: webroot
     persistentVolumeClaim:
       claimName: csi-s3-pvc
       readOnly: false
EOF


kubectl apply -f test2/

kubectl -n test2 exec pod/csi-s3-test-nginx -- sh -c 'ls -alh /usr/share/nginx/html/s3'


figlet "Holy freak it works!"


# figlet 'Jupyterhub'
# see ./jupterhub.sh