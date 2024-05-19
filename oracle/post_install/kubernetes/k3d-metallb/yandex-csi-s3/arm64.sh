#!/bin/bash

source ~/.bashrc

# --- # --- # --- # --- 
# --- # --- # --- # --- 
# Install GOLANG
# --- # --- # --- # --- 
# --- # --- # --- # --- 

figlet 'Install Golang'

export GOLANG_TAR="https://go.dev/dl/go1.22.3.linux-arm64.tar.gz"
curl -LO ${GOLANG_TAR}
ls -alh ./go1.22.3.linux-arm64.tar.gz

if [ -f /usr/local/go ]; then
  rm -rf /usr/local/go
fi;

sudo tar -C /usr/local -xzf ./go1.22.3.linux-arm64.tar.gz
export PATH=$PATH:/usr/local/go/bin

echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc

go version
# --- # --- # --- # --- 
# --- # --- # --- # --- 
# --- BUILD IT
# --- # --- # --- # --- 
# --- # --- # --- # --- 


figlet 'Build ARM64 S3 Csi Driver'

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo -E apt-get install -y build-essential

# Credits to https://github.com/motoki317/k8s-csi-s3.git

git clone https://github.com/decoder-leco/k8s-csi-s3.git ./k8s-csi-s3-arm64
cd ./k8s-csi-s3-arm64
git checkout build-linux-arm64

make build

make container



# --- # --- # --- 
# --- # --- # --- 
# ---  PREPARE IMAGES FOR THE HELM CHART

figlet 'Prepare S3 CSI Driver ARM64 Images'

# --
# - first image: the CSI driver i re-built
export REBUILT_CSI_DRIVER_IMG_NAME=$(docker images | grep yandex | head -n 1 | awk '{ print $1 }')
export REBUILT_CSI_DRIVER_IMG_TAG=$(docker images | grep yandex | head -n 1 | awk '{ print $2 }')
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






figlet 'Prepare Minio'


export minio_container_name="minio"
# export MINIO_BUCKET_URL="http://${minio_container_name}:9000/juicefs"
docker network connect "kind" "${minio_container_name}"

figlet 'Install Minio CLI'


sudo wget https://dl.min.io/client/mc/release/linux-arm64/mc -O /usr/bin/mc && sudo chmod +x /usr/bin/mc
mc --version

cat <<ETOF >./test.txt
This is a test file for minio, its
purpose is to test :
- the minio installation
- the minio CLI install and config
This text file is pushed to a minio bucket
This example is running on ARMv8 64bits CPU arch
aarch64
ETOF

# COPY <<ETOF /configure_minio.sh
# #!/bin/bash
# set -eux
# /usr/bin/mc alias set k8s-minio-dev http://localhost:9000 minioadmin minioadmin
# /usr/bin/mc mb k8s-minio-dev/test-bucket
# /usr/bin/mc cp /test.txt k8s-minio-dev/test-bucket
# ETOF
# chmod +x /configure_minio.sh
export minio_container_name="minio"
export MINIO_CSI_DRIVER_ROOT_USER='MINIO_CSI_DRIVER_ROOT_USERNAME'
export MINIO_CSI_DRIVER_ROOT_PASSWORD='bshwDxFP0vFBhob+6VxjtQrXBpRtWmammNjBwVUssFc='

export MINIO_ROOT_USER=${MINIO_CSI_DRIVER_ROOT_USER:-"ROOTNAME"}
export MINIO_ROOT_PASSWORD=${MINIO_CSI_DRIVER_ROOT_PASSWORD:-"CHANGEME123"}

export MINIO_ENDPOINT="http://${minio_container_name}:9000"
# export MINIO_ACCESS_KEY="f7a5aJLswKEwYcmZAGXW"
# export MINIO_SECRET_KEY="P6KujEDBpEoud9oBwHHGzCdzSEAm3P1TxZnzARtT"
echo "MINIO_CSI_DRIVER_ROOT_USER=[$MINIO_CSI_DRIVER_ROOT_USER]"
echo "MINIO_ROOT_USER=[$MINIO_ROOT_USER]"
# echo "MINIO_ROOT_PASSWORD=$[$MINIO_ROOT_PASSWORD]"



mc alias set targetted_minio http://localhost:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"
# mc ping targetted_minio

mc mb targetted_minio/minio-test-bucket
mc cp ./test.txt targetted_minio/minio-test-bucket

# https://min.io/docs/minio/linux/reference/minio-mc-admin/mc-admin-user-svcacct-add.html

export OUTPUT_SECRETS_MINIO=$(mc admin user svcacct add --name yandex_s3_csi_driver targetted_minio ${MINIO_ROOT_USER} --quiet)
export CSI_DRIVER_MINIO_ACCESSKEY=$(echo "$OUTPUT_SECRETS_MINIO" | grep 'Access Key' | awk '{ print $NF }')
export CSI_DRIVER_MINIO_SECRETKEY=$(echo "$OUTPUT_SECRETS_MINIO" | grep 'Secret Key' | awk '{ print $NF }')

echo "CSI_DRIVER_MINIO_ACCESSKEY=[${CSI_DRIVER_MINIO_ACCESSKEY}]"
echo "CSI_DRIVER_MINIO_SECRETKEY=[${CSI_DRIVER_MINIO_SECRETKEY}]"







figlet 'Deploy S3 CSI Driver'


helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts

helm delete csi-s3 -n kube-system || true

helm install csi-s3 yandex-s3/csi-s3 \
     -n kube-system \
     --set secret.accessKey=${CSI_DRIVER_MINIO_ACCESSKEY} \
     --set secret.secretKey=${CSI_DRIVER_MINIO_SECRETKEY} \
     --set secret.endpoint=${MINIO_ENDPOINT} \
     --set images.provisioner=${CSI_PROVISIONER_GUN_TO_DEPLOY} \
     --set images.csi=${CSI_DRIVER_GUN_TO_DEPLOY} \
     --set images.registrar=${CSI_REGISTRAR_GUN_TO_DEPLOY}



figlet 'Test S3 CSI Driver'


kubectl get all -n kube-system --selector=app=csi-s3-provisioner
kubectl logs service/csi-s3-provisioner -n kube-system
kubectl describe pod/csi-s3-provisioner-0 -n kube-system
kubectl describe service/csi-s3-provisioner -n kube-system


kubectl create ns s3-csi-driver-tests
mkdir -p s3-csi-driver-tests/
cat <<EOF >./s3-csi-driver-tests/pvc.yaml
# Dynamically provisioned PVC:
# A bucket or path inside bucket will be created automatically
# for the PV and removed when the PV will be removed
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-s3-pvc
  namespace: s3-csi-driver-tests
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: csi-s3
EOF

cat <<EOF >./s3-csi-driver-tests/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: csi-s3-test-nginx
  namespace: s3-csi-driver-tests
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


kubectl apply -f s3-csi-driver-tests/

kubectl -n s3-csi-driver-tests exec pod/csi-s3-test-nginx -- sh -c 'ls -alh /usr/share/nginx/html/s3'

figlet '---'
echo 'kubectl get all -n s3-csi-driver-tests'
figlet "Holy Molly S3 CSI DRIVER works!"
figlet '---'
echo 'kubectl get all -n s3-csi-driver-tests'
figlet '---'

# figlet 'Jupyterhub'
# see ./jupterhub.sh