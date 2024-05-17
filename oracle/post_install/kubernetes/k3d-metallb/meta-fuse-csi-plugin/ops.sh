#!/bin/bash

# ---
# 
# sudo apt-get install -y build-essential
# # requires reboot
# sudo reboot -h now
# ---
# -> After reboot, you have to restart the kind cluster load balancer (HA proxy)
# 
# docker start k8-lab-decoderleco-external-load-balancer || true
# 
export DESIRED_VERSION=${DESIRED_VERSION:-'v0.1.0'}
git clone https://github.com/pfnet-research/meta-fuse-csi-plugin ~/.meta-fuse-csi-driver

cd ~/.meta-fuse-csi-driver

git checkout ${DESIRED_VERSION}

# Adapt for ARM64
sed -i "s#--platform linux/amd64#--platform linux/arm64#g" ./Makefile
# sed -i "s#FROM gke.gcr.io/debian-base:bullseye-v1.4.3-gke.5 as debian#FROM gke.gcr.io/debian-base:bullseye-v1.4.3-gke.5:\$TARGETARCH-latest as debian#g" ./cmd/csi_driver/Dockerfile
# sed -i "s#FROM gcr.io/distroless/base-debian11 as distroless-base#FROM gcr.io/distroless/base-debian11:\$TARGETARCH-latest as distroless-base#g" ./cmd/csi_driver/Dockerfile
sed -i "s#FROM distroless-base AS distroless-amd64#FROM distroless-base AS distroless-arm64#g" ./cmd/csi_driver/Dockerfile

# --- now libs for ARCH64

sed -i "s#ENV LIB_DIR_PREFIX x86_64#ENV LIB_DIR_PREFIX aarch64#g" ./cmd/csi_driver/Dockerfile
sed -i "s~# The distroless amd64 image has a target triplet of x86_64~# The distroless amd64 image has a target triplet of aarch64~g" ./cmd/csi_driver/Dockerfile


# 0./ build docker images

chmod +x *.sh

./build-for-kind.sh || true

export IMG_GUN="ghcr.io/pfnet-research/meta-fuse-csi-plugin/meta-fuse-csi-plugin:latest"
docker tag ${IMG_GUN} localhost:5001/${IMG_GUN}

docker push localhost:5001/${IMG_GUN}

# 1./ deploy the CSI driver

sed -i "s#image: ${IMG_GUN}#image: ocalhost:5001/${IMG_GUN}#g" ./deploy/csi-driver.yaml
sed -i "s#image: ${IMG_GUN}#image: localhost:5001/${IMG_GUN}#g" ./deploy/csi-driver-daemonset.yaml

kubectl apply -f ./deploy/csi-driver.yaml
kubectl apply -f ./deploy/csi-driver-daemonset.yaml

figlet "Check MFCP deployment"

kubectl get ds -n mfcp-system


figlet "Deploy Example"




# ---
# # The below image is used to spin up
# # the 'starter' container of the example pod [ ./examples/proxy/mountpoint-s3/deploy.yaml]
# # And this image needs to be adpated and re-built locally for ARM64
# ---
# ghcr.io/pfnet-research/meta-fuse-csi-plugin/mfcp-example-proxy-mountpoint-s3:latest
# export IMG_GUN="ghcr.io/pfnet-research/meta-fuse-csi-plugin/mfcp-example-proxy-mountpoint-s3:latest"
# sed -i "s#image: ${IMG_GUN}#image: localhost:5001/${IMG_GUN}#g" ./examples/proxy/mountpoint-s3/deploy.yaml

export MINIO_IMG_GUN="quay.io/minio/minio:latest"
docker pull ${MINIO_IMG_GUN}
docker tag ${MINIO_IMG_GUN} localhost:5001/${MINIO_IMG_GUN}
docker push localhost:5001/${MINIO_IMG_GUN}
sed -i "s#image: ${MINIO_IMG_GUN}#image: localhost:5001/${MINIO_IMG_GUN}#g" ./examples/proxy/mountpoint-s3/deploy.yaml

export BUSYBOX_IMG_GUN="busybox"
docker pull ${BUSYBOX_IMG_GUN}
docker tag ${BUSYBOX_IMG_GUN} localhost:5001/${BUSYBOX_IMG_GUN}
docker push localhost:5001/${BUSYBOX_IMG_GUN}
sed -i "s#image: ${BUSYBOX_IMG_GUN}#image: localhost:5001/${BUSYBOX_IMG_GUN}#g" ./examples/proxy/mountpoint-s3/deploy.yaml


# OK, I found what is not OK : 
# > with the starter container of the pod: that's the one which has the error
# > the starter container image is only available for amd64 x86_64: SO i need to build my own image of the starter, which will probably require to build the starter go package from source

# Building starter image:

# cat ./examples/proxy/mountpoint-s3/Dockerfile

cat <<EOF >./examples/proxy/mountpoint-s3/Dockerfile
FROM golang:1.20.7 as fusermount3-proxy-builder

WORKDIR /meta-fuse-csi-plugin
ADD . .
RUN make fusermount3-proxy BINDIR=/bin

FROM ubuntu:22.04

RUN apt update && apt upgrade -y
RUN apt install -y ca-certificates wget libfuse2 fuse3

# prepare for MinIO
RUN wget https://dl.min.io/client/mc/release/linux-arm64/mc -O /usr/bin/mc && chmod +x /usr/bin/mc
# RUN wget https://dl.min.io/client/mc/release/linux-arm64/mc.deb -O mc.deb && ls -alh ./mc.deb && dpkg -i ./mc.deb && apt-get install -y
RUN mc --version

COPY <<ETOF /test.txt
This is a test file for minio
This text file is pushed to minio bucket
from the starter container of the example pod
[./examples/proxy/mountpoint-s3/deploy.yaml]
This example is running on ARMv8 64bits CPU arch
aarch64
ETOF

COPY <<ETOF /configure_minio.sh
#!/bin/bash
set -eux
/usr/bin/mc alias set k8s-minio-dev http://localhost:9000 minioadmin minioadmin
/usr/bin/mc mb k8s-minio-dev/test-bucket
/usr/bin/mc cp /test.txt k8s-minio-dev/test-bucket
ETOF
RUN chmod +x /configure_minio.sh

# RUN wget https://s3.amazonaws.com/mountpoint-s3-release/1.0.1/x86_64/mount-s3-1.0.1-x86_64.deb -O mount-s3.deb && dpkg -i mount-s3.deb
RUN wget https://s3.amazonaws.com/mountpoint-s3-release/1.0.1/arm64/mount-s3-1.0.1-arm64.deb -O mount-s3.deb && dpkg -i mount-s3.deb

COPY --from=fusermount3-proxy-builder /bin/fusermount3-proxy /bin/fusermount3
RUN ln -sf /bin/fusermount3 /bin/fusermount
EOF


# git checkout  ./examples/proxy/mountpoint-s3/Dockerfile

make build-examples

# after it's built, I need to docker tag and push to local registry
export STARTER_IMG_GUN="$(docker images | grep mfcp-example-proxy-mountpoint-s3 | grep dirty | awk '{ print $1 }'):$(docker images | grep mfcp-example-proxy-mountpoint-s3 | grep dirty | awk '{ print $2 }')"
docker tag ${STARTER_IMG_GUN} localhost:5001/${STARTER_IMG_GUN}-arm64-beta
docker push localhost:5001/${STARTER_IMG_GUN}-arm64-beta

# git checkout ./examples/proxy/mountpoint-s3/deploy.yaml
export PREV_STARTER_IMG_GUN="ghcr.io/pfnet-research/meta-fuse-csi-plugin/mfcp-example-proxy-mountpoint-s3:latest"
export TO_REPLACE="${PREV_STARTER_IMG_GUN}"
export TO_REPLACE_BY="localhost:5001/${STARTER_IMG_GUN}-arm64-beta"
sed -i "s#${TO_REPLACE}#${TO_REPLACE_BY}#g" ./examples/proxy/mountpoint-s3/deploy.yaml


kubectl apply -f ./examples/proxy/mountpoint-s3/deploy.yaml
# kubectl delete -f ./examples/proxy/mountpoint-s3/deploy.yaml
kubectl get pods mfcp-example-proxy-mountpoint-s3

kubectl logs pod/mfcp-example-proxy-mountpoint-s3 -c starter
kubectl logs pod/mfcp-example-proxy-mountpoint-s3 -c minio
kubectl logs pod/mfcp-example-proxy-mountpoint-s3 -c busybox

kubectl exec pod/mfcp-example-proxy-mountpoint-s3 -c starter -- sh -c "pwd"


figlet 'final test in busybox'

kubectl exec pod/mfcp-example-proxy-mountpoint-s3 -c busybox -- sh -c "cat /data/test.txt"

# ----
# Ok It now works on ARM64, but I am not sure I can do dynamic volume provisioning with that csi driver, unfortunately... 

# https://github.com/pfnet-research/meta-fuse-csi-plugin/issues/5
