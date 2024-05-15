#!/bin/bash

# https://juicefs.com/docs/csi/getting_started#helm

# 1./ Execute the following command on any non-Master node in the Kubernetes cluster.

export KND_CLUSTER_NAME='k8-lab-decoderleco'
kind get nodes -n "${KND_CLUSTER_NAME}"

export WORKER_NODE=$(kind get nodes -n k8-lab-decoderleco | grep worker | head -n 1)
echo "WORKER_NODE=[${WORKER_NODE}]"

export CMD_TO_EXECUTE="ps -ef | grep kubelet | grep root-dir"
docker exec -it ${WORKER_NODE} sh -c 'ps -ef | grep kubelet | grep root-dir'
docker exec -it ${WORKER_NODE} sh -c 'ps -ef | grep kubelet'


helm repo add juicefs https://juicedata.github.io/charts/
helm repo update

mkdir juicefs-csi-driver && cd juicefs-csi-driver
touch values-mycluster.yaml
# helm upgrade --install juicefs-csi-driver juicefs/juicefs-csi-driver -n kube-system -f ./values-mycluster.yaml
helm upgrade --install juicefs-csi-driver juicefs/juicefs-csi-driver -n kube-system

export minio_container_name="minio"
# docker network connect "kind" "${minio_container_name}"
export MINIO_BUCKET_URL="http://${minio_container_name}:9000/juicefs"
export MINIO_ACCESS_KEY="EVZInRuLQ7EcAVVaP7rp"
export MINIO_SECRET_KEY="zOW2r4vd2yvvKNbRmoSU0awwbi5CL63K6708WyM3"

export JUICEFS_METADATA_URL="sqlite3://myjfs.db"

figlet 'JuiceFS SC'
cat <<EOF >./juicefs_sc.yaml
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-secret
  namespace: default
type: Opaque
stringData:
  name: juicefs-vol                # The JuiceFS file system name
  access-key: ${MINIO_ACCESS_KEY}  # Object storage credentials
  secret-key: ${MINIO_SECRET_KEY}  # Object storage credentials
  # follows are for JuiceFS enterprise
  # token: ${JUICEFS_TOKEN}        # Token used to authenticate against JuiceFS Volume
  # follows are for JuiceFS community
  metaurl: ${JUICEFS_METADATA_URL} # Connection URL for metadata engine.
  storage: s3                      # Object storage type, such as s3, gs, oss.
  bucket: ${MINIO_BUCKET_URL}      # Bucket URL of object storage.
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: juicefs-sc
provisioner: csi.juicefs.com
parameters:
  csi.storage.k8s.io/provisioner-secret-name: juicefs-secret
  csi.storage.k8s.io/provisioner-secret-namespace: default
  csi.storage.k8s.io/node-publish-secret-name: juicefs-secret
  csi.storage.k8s.io/node-publish-secret-namespace: default
  # subDir: \${pvc.metadata.namespace}-\${pvc.metadata.name}-\${pv.metadata.name}  ### Folder/subdir name template
  pathPattern: "\${.PVC.namespace}-\${.PVC.name}-\${.PV.name}"
EOF
kubectl apply -f ./juicefs_sc.yaml
```

```bash

figlet 'JuiceFS Test'
cat <<EOF >./juicefs_test.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: juicefs-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100
      # storage: 10Pi
  storageClassName: juicefs-sc
---
apiVersion: v1
kind: Pod
metadata:
  name: juicefs-app
  namespace: default
spec:
  containers:
  - args:
    - -c
    - while true; do echo $(date -u) >> /data/out.txt; sleep 5; done
    command:
    - /bin/sh
    image: busybox
    name: app
    volumeMounts:
    - mountPath: /data
      name: juicefs-pv
  volumes:
  - name: juicefs-pv
    persistentVolumeClaim:
      claimName: juicefs-pvc

EOF

kubectl apply -f ./juicefs_test.yaml


```