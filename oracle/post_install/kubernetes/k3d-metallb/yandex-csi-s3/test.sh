#!/bin/bash

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



























cat <<EOF >./pvc-manual.yaml
# Statically provisioned PVC:
# An existing bucket or path inside bucket manually created
# by the administrator beforehand will be bound to the PVC,
# and it won't be removed when you remove the PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manualbucket-with-path
spec:
  storageClassName: csi-s3
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  claimRef:
    namespace: test2
    name: csi-s3-manual-pvc
  csi:
    driver: ru.yandex.s3.csi
    controllerPublishSecretRef:
      name: csi-s3-secret
      namespace: kube-system
    nodePublishSecretRef:
      name: csi-s3-secret
      namespace: kube-system
    nodeStageSecretRef:
      name: csi-s3-secret
      namespace: kube-system
    volumeAttributes:
      capacity: 10Gi
      mounter: geesefs
      options: --memory-limit 1000 --dir-mode 0777 --file-mode 0666
    volumeHandle: manualbucket/path
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-s3-manual-pvc
spec:
  # Empty storage class disables dynamic provisioning
  storageClassName: ""
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

cat <<EOF >./ccc.yaml

EOF

