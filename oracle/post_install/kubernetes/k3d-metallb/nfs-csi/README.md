# The NFS CSI Driver


## Setup an NFS server

```bash
mkdir -p ~/.nfs-service
cd ~/.nfs-service

sudo mkdir -p /mnt/nfs_data/k8s_storage
sudo chown $USER: -R /mnt/nfs_data

cat <<EOF >./docker-compose.yml
---
version: "3.9"
services:
  nfs-server:
    image: mekayelanik/nfs-server-alpine:latest
    container_name: nfs-server-1
    environment:
      # - TZ=Asia/Dhaka
      # - ALLOWED_CLIENT=192.168.1.1/24
      - ALLOWED_CLIENT=0.0.0.0
      - NFS_MOUNT_PORT=2049
# Number of Shares without ROOT DIR
      # - NUMBER_OF_SHARES=2
      - NUMBER_OF_SHARES=1
      - NFS_EXPORT_1=k8s_storage
      # - NFS_EXPORT_1=Movies
      # - NFS_EXPORT_2=Music
    privileged: true
    volumes:
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
# # Don't touch the FOLLOWING Mapping (/lib/modules). This is REQUIRED to run NFS as a container. ('sys_module' modprobe )
      - /lib/modules:/lib/modules
# NFS Root directory in this container '/data' MUST BE MAPPED to a valid directory in the Host (Server Machine)
## You CAN'T use different parent directory (for example /mnt/drive2/Movies) for child shares.
### To share different Child shares on another Parent directory, you must use deploy another container. (Sorry, but this is how the NFS works)
#### To create More than one NFS server container, please use MACVLAN as given example below. https://github.com/MekayelAnik/nfs-server-alpine
      - /mnt/nfs_data:/data
      - /mnt/nfs_data/k8s_storage:/data/k8s_storage
      # - /mnt/nfs_data/k8s_storage/Movies:/data/Movies
      # - /mnt/nfs_data/k8s_storage/Music:/data/Music
    ports:
      - 0.0.0.0:2049:2049
      # - 0.0.0.0:111:111
      - 0.0.0.0:32765-32767:32765-32767
# Don't touch the FOLLOWING Section. This is REQUIRED to run NFS as a container (cap_add).
    cap_add:
      - SYS_ADMIN
      - SETPCAP
      - ALL
    restart: unless-stopped
EOF

docker-compose up -d
```

In the docker compose logs, I can see that I ma using nfs version `4.2`:

```bash

nfs-server-1  |  88    8b. 88    88 88    88 88    88 88    88 88    88   88        88   88    88    88    88 88    88 88    88    88    88 88    88
nfs-server-1  |  88    .88 88       88.  .88 88.  .88 88.  .88 88    88   88        88   88.  .88    88.  .88 88.  .88 88.  .88    88.  .88 88.  .88 dP
nfs-server-1  |  88888888P dP        88888P   88888P   8888P88 dP    dP   888P      888P  88888P      8888P88  88888P   88888P     88Y8888   8888P88 88
nfs-server-1  |                                            .88                                           .88                                     .88
nfs-server-1  |                                        d8888P                                        d8888P                                  d8888P
nfs-server-1  |
nfs-server-1  |
nfs-server-1  |  ███╗   ███╗██████╗        ███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗   ██╗███████╗██╗          █████╗ ███╗   ██╗██╗██╗  ██╗
nfs-server-1  |  ████╗ ████║██╔══██╗       ████╗ ████║██╔════╝██║ ██╔╝██╔══██╗╚██╗ ██╔╝██╔════╝██║         ██╔══██╗████╗  ██║██║██║ ██╔╝
nfs-server-1  |  ██╔████╔██║██║  ██║       ██╔████╔██║█████╗  █████╔╝ ███████║ ╚████╔╝ █████╗  ██║         ███████║██╔██╗ ██║██║█████╔╝
nfs-server-1  |  ██║╚██╔╝██║██║  ██║       ██║╚██╔╝██║██╔══╝  ██╔═██╗ ██╔══██║  ╚██╔╝  ██╔══╝  ██║         ██╔══██║██║╚██╗██║██║██╔═██╗
nfs-server-1  |  ██║ ╚═╝ ██║██████╔╝██╗    ██║ ╚═╝ ██║███████╗██║  ██╗██║  ██║   ██║   ███████╗███████╗    ██║  ██║██║ ╚████║██║██║  ██╗
nfs-server-1  |  ╚═╝     ╚═╝╚═════╝ ╚═╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
nfs-server-1  | ________________________________________________________________________________________________________________________________________________
nfs-server-1  |
nfs-server-1  |  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> NFS Server! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
nfs-server-1  |
nfs-server-1  |  To Mount from this NFS Server use : sudo mount -v -o vers=4.2,loud 172.24.0.2:/ /mount/path/to/ROOT-SHARE-DIR
nfs-server-1  |  Or in /etc/fstab make entry: 172.24.0.2:/YOUR-SHARE-NAME    /path/to/mount    nfs    vers=4.2,defaults,proto=tcp,port=2049    0 0
nfs-server-1  |

```

## Deploy the CSI Driver

* https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/deploy/example/README.md#prerequisite
* https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/charts
* https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/
* https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/

### Determine the kubelet dir

* To determine the kubelet dir, execute the following command on any non-Master node in the Kubernetes cluster:

```bash
export KND_CLUSTER_NAME='k8-lab-decoderleco'
kind get nodes -n "${KND_CLUSTER_NAME}"

export WORKER_NODE=$(kind get nodes -n k8-lab-decoderleco | grep worker | head -n 1)
echo "WORKER_NODE=[${WORKER_NODE}]"

export CMD_TO_EXECUTE="ps -ef | grep kubelet | grep root-dir"
docker exec -it ${WORKER_NODE} sh -c 'ps -ef | grep kubelet | grep root-dir'
docker exec -it ${WORKER_NODE} sh -c 'ps -ef | grep kubelet'
```

If the kubelet dir path is different than `/var/lib/kubelet`, you will then have to set the `kubeletDir` configuration value in the helm chart to deploy the NFS CSI driver. With my kind cluster I get:

```bash
~$ docker exec -it ${WORKER_NODE} sh -c 'ps -ef | grep kubelet'
root         254       1  1 16:14 ?        00:00:06 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///run/containerd/containerd.sock --node-ip=172.18.0.3 --node-labels= --pod-infra-container-image=registry.k8s.io/pause:3.9 --provider-id=kind://docker/k8-lab-decoderleco/k8-lab-decoderleco-worker2 --runtime-cgroups=/system.slice/containerd.service
root        1868       0  0 16:24 pts/1    00:00:00 sh -c ps -ef | grep kubelet
root        1875    1868  0 16:24 pts/1    00:00:00 grep kubelet

```

The `--config=/var/lib/kubelet/config.yaml` tells me that the kubelet dir is `/var/lib/kubelet/`

```bash
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update


export KUBELET_DIR="/var/snap/microk8s/common/var/lib/kubelet"
export KUBELET_DIR="/var/lib/kubelet"
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --set kubeletDir=${KUBELET_DIR}
```

```bash
kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/instance=csi-driver-nfs" --watch
```

```bash
export NFS_SERVER_CONTAINER_NAME="nfs-server-1"
export K3D_NET_NAME="kind"
docker network connect "${K3D_NET_NAME}" "${NFS_SERVER_CONTAINER_NAME}" || true
```

```bash

export NFS_SERVER_CONTAINER_NAME="nfs-server-1"

cat <<EOF >./csi-driver-storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER_CONTAINER_NAME}
  share: /
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  # csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  # csi.storage.k8s.io/provisioner-secret-namespace: "default"
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.2
EOF

kubectl apply -f ./csi-driver-storage-class.yaml

# test using the storage class

cat <<EOF >./test-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-dynamic
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: nfs-csi
EOF

kubectl create ns test 
kubectl apply -f ./test-pvc.yaml -n test

cat <<EOF >./test-pod.yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: nginx-nfs
spec:
  nodeSelector:
    "kubernetes.io/os": linux
  containers:
    - image: mcr.microsoft.com/oss/nginx/nginx:1.19.5
      name: nginx-nfs
      command:
        - "/bin/bash"
        - "-c"
        - set -euo pipefail; while true; do echo $(date) >> /mnt/nfs/outfile; sleep 1; done
      volumeMounts:
        - name: persistent-storage
          mountPath: "/mnt/nfs"
          readOnly: false
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: pvc-nfs-dynamic

EOF

kubectl apply -f ./test-pod.yaml -n test


```

```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

cat <<EOF >./config.yaml
singleuser:
  storage:
    capacity: 2Gi
    dynamic:
      storageClass: nfs-csi
EOF
# helm delete decoderleco-jupyter -n decoderleco
helm upgrade --cleanup-on-fail \
  --install decoderleco-jupyter jupyterhub/jupyterhub \
  --namespace decoderleco \
  --create-namespace \
  --version=3.3.7 \
  --values config.yaml

helm delete decoderleco-jupyter -n decoderleco

```

And it does not work, I get this error:

```bash
2024-05-14T19:07:44.394431Z [Warning] 0/4 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling..
```


je pense que l'erreur vient du fait que je devrais, donner à la valeur du `share` dans la StorageClass, à `/data/k8s_storage`, au lieu de `/` cf. le docker-compose du serveur nfs.