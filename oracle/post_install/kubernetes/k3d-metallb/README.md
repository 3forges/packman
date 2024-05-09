# k3d with metallb

Source https://medium.com/@jinvishal2011/creating-an-efficient-and-lightweight-kubernetes-cluster-on-linux-with-k3d-metallb-and-nginx-a5297996e28b

The goal of this work is to try and adapt the source published article to aarch64.

## Errors stack

### Frst error: deploying metallb

```bash
~$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml
serviceaccount/controller created
serviceaccount/speaker created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
role.rbac.authorization.k8s.io/config-watcher created
role.rbac.authorization.k8s.io/pod-lister created
role.rbac.authorization.k8s.io/controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/config-watcher created
rolebinding.rbac.authorization.k8s.io/pod-lister created
rolebinding.rbac.authorization.k8s.io/controller created
daemonset.apps/speaker created
deployment.apps/controller created
resource mapping not found for name: "controller" namespace: "metallb-system" from "https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml": no matches for kind "PodSecurityPolicy" in version "policy/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "speaker" namespace: "metallb-system" from "https://raw.githubusercontent.com/metallb/metallb/v0.10.3/manifests/metallb.yaml": no matches for kind "PodSecurityPolicy" in version "policy/v1beta1"
ensure CRDs are installed first

```

* https://github.com/metallb/metallb/issues/1574


It seems my issue might be fixed if i would switch to a different deplyment method of metallb, using Bitnami's helm chart instead of the source article suggested deployment method.


COnfiguring the deployment required a bit a research. 

Yet, deploying the default gave suseful infos:

```bash
~/bitnamischarts/bitnami/metallb$ kubectl get cm
NAME                         DATA   AGE
kube-root-ca.crt             1      40m
metallb-decoderleco-config   1      14m
config                       1      8m47s
~/bitnamischarts/bitnami/metallb$ kubectl describe cm/config
Name:         config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
config:
----
address-pools:
- name: default
  protocol: layer2
  addresses:
  - 172.19.0.240/29


BinaryData
====

Events:  <none>
~/bitnamischarts/bitnami/metallb$ kubectl describe cm/metallb-decoderleco-config
Name:         metallb-decoderleco-config
Namespace:    default
Labels:       app.kubernetes.io/instance=metallb-decoderleco
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=metallb
              app.kubernetes.io/version=0.14.5
              helm.sh/chart=metallb-6.1.4
Annotations:  meta.helm.sh/release-name: metallb-decoderleco
              meta.helm.sh/release-namespace: default

Data
====
config:
----
null


BinaryData
====

Events:  <none>

```

to analyze my chart :

```bash
helm template metallb-decoderleco ./ -n metallb-system > rendered-chart.yaml
```

And in the `rendered-chart.yaml`, I found:

```Yaml
---
# Source: metallb/templates/controller/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: metallb-decoderleco-config
  namespace: "metallb-system"
  labels:
    app.kubernetes.io/instance: metallb-decoderleco
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: metallb
    app.kubernetes.io/version: 0.14.5
    helm.sh/chart: metallb-6.1.4
data:
  config: |
    null
```

Now, in the Helm Chart source code, in the `metallb/templates/controller/configmap.yaml` file I find the following content:

```Yaml
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
  labels: {{- include "common.labels.standard" ( dict "customLabels" .Values.commonLabels "context" $ ) | nindent 4 }}
  {{- if .Values.commonAnnotations }}
  annotations: {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
  {{- end }}
data:
  config: |
{{ include "common.tplvalues.render" ( dict "value" .Values.configInline "context" $) | indent 4 }}
{{- end -}}
```

Since I was lazy about understanding what exact helm values I should set, I just decided to do this before running helm install:

```bash
export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')

echo "K3D_NET_CIDR_BLOCK=[${K3D_NET_CIDR_BLOCK}]"

export K3D_NET_BASE_ADDR=${K3D_NET_CIDR_BLOCK%???}

export K3D_NET_FIRST_ADDR=$(echo $K3D_NET_CIDR_BLOCK | awk -F'.' '{print $1,$2,$3,240}' OFS='.')

export K3D_NET_RANGE="$K3D_NET_FIRST_ADDR/29"


echo "K3D_NET_BASE_ADDR=[${K3D_NET_BASE_ADDR}]"
echo "K3D_NET_FIRST_ADDR=[${K3D_NET_FIRST_ADDR}]"
echo "K3D_NET_RANGE=[${K3D_NET_RANGE}]"

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
{{ include "common.tplvalues.render" ( dict "value" .Values.configInline "context" \$) | indent 4 }}
{{- end -}}
EOF

```


Ok, now, doing that, I get the following configuration map for metallb after helm install:

```bash
~/bitnamischarts/bitnami/metallb$ kubectl describe cm/metallb-decoderleco-config -n metallb-system
Name:         metallb-decoderleco-config
Namespace:    metallb-system
Labels:       app.kubernetes.io/instance=metallb-decoderleco
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=metallb
              app.kubernetes.io/version=0.14.5
              helm.sh/chart=metallb-6.1.4
Annotations:  meta.helm.sh/release-name: metallb-decoderleco
              meta.helm.sh/release-namespace: metallb-system

Data
====
config:
----
address-pools:
- name: default
  protocol: layer2
  addresses:
  - 172.19.0.240/29
null


BinaryData
====

Events:  <none>

```


And I get the following error in the metallb controller:

```bash

~/bitnamischarts/bitnami/metallb$ kubectl logs deployment.apps/metallb-decoderleco-controller -n metallb-system | grep 'nginx'
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:24:35Z"}
{"caller":"service_controller.go:72","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:24:35Z"}
{"caller":"service_controller_reload.go:108","controller":"ServiceReconciler - reprocessAll","endpoints":"[]","event":"failed to handle service, no retry","level":"error","name":"default/nginx","service":"{\"kind\":\"Service\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"nginx\",\"namespace\":\"default\",\"uid\":\"24cca6ec-e8a2-46b9-b742-fd95faa8996a\",\"resourceVersion\":\"2655\",\"creationTimestamp\":\"2024-05-08T20:41:42Z\",\"annotations\":{\"kubectl.kubernetes.io/last-applied-configuration\":\"{\\\"apiVersion\\\":\\\"v1\\\",\\\"kind\\\":\\\"Service\\\",\\\"metadata\\\":{\\\"annotations\\\":{},\\\"name\\\":\\\"nginx\\\",\\\"namespace\\\":\\\"default\\\"},\\\"spec\\\":{\\\"ports\\\":[{\\\"port\\\":80}],\\\"selector\\\":{\\\"app\\\":\\\"nginx\\\"},\\\"type\\\":\\\"LoadBalancer\\\"}}\\n\"},\"managedFields\":[{\"manager\":\"kubectl-client-side-apply\",\"operation\":\"Update\",\"apiVersion\":\"v1\",\"time\":\"2024-05-08T20:41:42Z\",\"fieldsType\":\"FieldsV1\",\"fieldsV1\":{\"f:metadata\":{\"f:annotations\":{\".\":{},\"f:kubectl.kubernetes.io/last-applied-configuration\":{}}},\"f:spec\":{\"f:allocateLoadBalancerNodePorts\":{},\"f:externalTrafficPolicy\":{},\"f:internalTrafficPolicy\":{},\"f:ports\":{\".\":{},\"k:{\\\"port\\\":80,\\\"protocol\\\":\\\"TCP\\\"}\":{\".\":{},\"f:port\":{},\"f:protocol\":{},\"f:targetPort\":{}}},\"f:selector\":{},\"f:sessionAffinity\":{},\"f:type\":{}}}}]},\"spec\":{\"ports\":[{\"protocol\":\"TCP\",\"port\":80,\"targetPort\":80,\"nodePort\":30387}],\"selector\":{\"app\":\"nginx\"},\"clusterIP\":\"10.43.56.250\",\"clusterIPs\":[\"10.43.56.250\"],\"type\":\"LoadBalancer\",\"sessionAffinity\":\"None\",\"externalTrafficPolicy\":\"Cluster\",\"ipFamilies\":[\"IPv4\"],\"ipFamilyPolicy\":\"SingleStack\",\"allocateLoadBalancerNodePorts\":true,\"internalTrafficPolicy\":\"Cluster\"},\"status\":{\"loadBalancer\":{}}}","ts":"2024-05-08T21:24:35Z"}
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:27:16Z"}
{"caller":"service_controller.go:115","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:27:16Z"}
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:27:18Z"}
{"caller":"service_controller.go:112","controller":"ServiceReconciler","endpoints":"[]","event":"failed to handle service","level":"error","name":"default/nginx","service":"{\"kind\":\"Service\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"nginx\",\"namespace\":\"default\",\"uid\":\"e0149f4e-e3ee-44c8-899d-598d30d12461\",\"resourceVersion\":\"4005\",\"creationTimestamp\":\"2024-05-08T21:27:18Z\",\"annotations\":{\"kubectl.kubernetes.io/last-applied-configuration\":\"{\\\"apiVersion\\\":\\\"v1\\\",\\\"kind\\\":\\\"Service\\\",\\\"metadata\\\":{\\\"annotations\\\":{},\\\"name\\\":\\\"nginx\\\",\\\"namespace\\\":\\\"default\\\"},\\\"spec\\\":{\\\"ports\\\":[{\\\"port\\\":80}],\\\"selector\\\":{\\\"app\\\":\\\"nginx\\\"},\\\"type\\\":\\\"LoadBalancer\\\"}}\\n\"},\"managedFields\":[{\"manager\":\"kubectl-client-side-apply\",\"operation\":\"Update\",\"apiVersion\":\"v1\",\"time\":\"2024-05-08T21:27:18Z\",\"fieldsType\":\"FieldsV1\",\"fieldsV1\":{\"f:metadata\":{\"f:annotations\":{\".\":{},\"f:kubectl.kubernetes.io/last-applied-configuration\":{}}},\"f:spec\":{\"f:allocateLoadBalancerNodePorts\":{},\"f:externalTrafficPolicy\":{},\"f:internalTrafficPolicy\":{},\"f:ports\":{\".\":{},\"k:{\\\"port\\\":80,\\\"protocol\\\":\\\"TCP\\\"}\":{\".\":{},\"f:port\":{},\"f:protocol\":{},\"f:targetPort\":{}}},\"f:selector\":{},\"f:sessionAffinity\":{},\"f:type\":{}}}}]},\"spec\":{\"ports\":[{\"protocol\":\"TCP\",\"port\":80,\"targetPort\":80,\"nodePort\":30283}],\"selector\":{\"app\":\"nginx\"},\"clusterIP\":\"10.43.205.204\",\"clusterIPs\":[\"10.43.205.204\"],\"type\":\"LoadBalancer\",\"sessionAffinity\":\"None\",\"externalTrafficPolicy\":\"Cluster\",\"ipFamilies\":[\"IPv4\"],\"ipFamilyPolicy\":\"SingleStack\",\"allocateLoadBalancerNodePorts\":true,\"internalTrafficPolicy\":\"Cluster\"},\"status\":{\"loadBalancer\":{}}}","ts":"2024-05-08T21:27:18Z"}
{"caller":"service_controller.go:113","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:27:18Z"}
~/bitnamischarts/bitnami/metallb$

```

I removed one line in the helm template of the configuraiton file, and run it all agai, so that i ended up with the following config map for meltallb (which this time didn't contain any weird null value):

```bash
~/bitnamischarts/bitnami/metallb$ kubectl describe cm/metallb-decoderleco-config -n metallb-system
Name:         metallb-decoderleco-config
Namespace:    metallb-system
Labels:       app.kubernetes.io/instance=metallb-decoderleco
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=metallb
              app.kubernetes.io/version=0.14.5
              helm.sh/chart=metallb-6.1.4
Annotations:  meta.helm.sh/release-name: metallb-decoderleco
              meta.helm.sh/release-namespace: metallb-system

Data
====
config:
----
address-pools:
- name: default
  protocol: layer2
  addresses:
  - 172.19.0.240/29


BinaryData
====

Events:  <none>

~/bitnamischarts/bitnami/metallb$ kubectl logs deployment.apps/metallb-decoderleco-controller -n metallb-system | grep 'config'
{"caller":"pool_controller.go:112","controller":"PoolReconciler","event":"config reloaded","level":"info","ts":"2024-05-08T21:39:09Z"}
{"level":"info","ts":"2024-05-08T21:39:10Z","logger":"cert-rotation","msg":"Ensuring CA cert","name":"metallb-webhook-configuration","gvk":"admissionregistration.k8s.io/v1, Kind=ValidatingWebhookConfiguration","name":"metallb-webhook-configuration","gvk":"admissionregistration.k8s.io/v1, Kind=ValidatingWebhookConfiguration","stacktrace":"github.com/open-policy-agent/cert-controller/pkg/rotator.(*ReconcileWH).ensureCerts\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/github.com/open-policy-agent/cert-controller@v0.10.1/pkg/rotator/rotator.go:828\ngithub.com/open-policy-agent/cert-controller/pkg/rotator.(*ReconcileWH).Reconcile\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/github.com/open-policy-agent/cert-controller@v0.10.1/pkg/rotator/rotator.go:785\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).Reconcile\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/sigs.k8s.io/controller-runtime@v0.17.3/pkg/internal/controller/controller.go:119\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).reconcileHandler\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/sigs.k8s.io/controller-runtime@v0.17.3/pkg/internal/controller/controller.go:316\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).processNextWorkItem\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/sigs.k8s.io/controller-runtime@v0.17.3/pkg/internal/controller/controller.go:266\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).Start.func2.2\n\t/bitnami/blacksmith-sandox/metallb-0.14.5/pkg/mod/sigs.k8s.io/controller-runtime@v0.17.3/pkg/internal/controller/controller.go:227"}

```

And after deploying the nginx, I still ge the same error:

```bash
~/bitnamischarts/bitnami/metallb$ kubectl logs deployment.apps/metallb-decoderleco-controller -n metallb-system | grep 'nginx'
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:112","controller":"ServiceReconciler","endpoints":"[]","event":"failed to handle service","level":"error","name":"default/nginx","service":"{\"kind\":\"Service\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"nginx\",\"namespace\":\"default\",\"uid\":\"e770d426-cbf5-4dca-8793-9601b0336df4\",\"resourceVersion\":\"4611\",\"creationTimestamp\":\"2024-05-08T21:42:16Z\",\"annotations\":{\"kubectl.kubernetes.io/last-applied-configuration\":\"{\\\"apiVersion\\\":\\\"v1\\\",\\\"kind\\\":\\\"Service\\\",\\\"metadata\\\":{\\\"annotations\\\":{},\\\"name\\\":\\\"nginx\\\",\\\"namespace\\\":\\\"default\\\"},\\\"spec\\\":{\\\"ports\\\":[{\\\"port\\\":80}],\\\"selector\\\":{\\\"app\\\":\\\"nginx\\\"},\\\"type\\\":\\\"LoadBalancer\\\"}}\\n\"},\"managedFields\":[{\"manager\":\"kubectl-client-side-apply\",\"operation\":\"Update\",\"apiVersion\":\"v1\",\"time\":\"2024-05-08T21:42:16Z\",\"fieldsType\":\"FieldsV1\",\"fieldsV1\":{\"f:metadata\":{\"f:annotations\":{\".\":{},\"f:kubectl.kubernetes.io/last-applied-configuration\":{}}},\"f:spec\":{\"f:allocateLoadBalancerNodePorts\":{},\"f:externalTrafficPolicy\":{},\"f:internalTrafficPolicy\":{},\"f:ports\":{\".\":{},\"k:{\\\"port\\\":80,\\\"protocol\\\":\\\"TCP\\\"}\":{\".\":{},\"f:port\":{},\"f:protocol\":{},\"f:targetPort\":{}}},\"f:selector\":{},\"f:sessionAffinity\":{},\"f:type\":{}}}}]},\"spec\":{\"ports\":[{\"protocol\":\"TCP\",\"port\":80,\"targetPort\":80,\"nodePort\":31329}],\"selector\":{\"app\":\"nginx\"},\"clusterIP\":\"10.43.96.58\",\"clusterIPs\":[\"10.43.96.58\"],\"type\":\"LoadBalancer\",\"sessionAffinity\":\"None\",\"externalTrafficPolicy\":\"Cluster\",\"ipFamilies\":[\"IPv4\"],\"ipFamilyPolicy\":\"SingleStack\",\"allocateLoadBalancerNodePorts\":true,\"internalTrafficPolicy\":\"Cluster\"},\"status\":{\"loadBalancer\":{}}}","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:113","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:16Z"}
~/bitnamischarts/bitnami/metallb$ kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7c5ddbdf54-6sntg   1/1     Running   0          2m15s

NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP      10.43.0.1     <none>        443/TCP        130m
service/nginx        LoadBalancer   10.43.96.58   <pending>     80:31329/TCP   2m15s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           2m15s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-7c5ddbdf54   1         1         1       2m15s

```

more infos / decribes logs at this point of the trouble shooting:

```bash
~/bitnamischarts/bitnami/metallb$ kubectl get all -n metallb-system
NAME                                                 READY   STATUS    RESTARTS      AGE
pod/metallb-decoderleco-speaker-9lkwg                1/1     Running   0             13m
pod/metallb-decoderleco-speaker-8mc9x                1/1     Running   0             13m
pod/metallb-decoderleco-controller-66794d977-6xtlh   1/1     Running   1 (13m ago)   13m

NAME                              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/metallb-webhook-service   ClusterIP   10.43.187.191   <none>        443/TCP   13m

NAME                                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/metallb-decoderleco-speaker   2         2         2       2            2           kubernetes.io/os=linux   13m

NAME                                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/metallb-decoderleco-controller   1/1     1            1           13m

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/metallb-decoderleco-controller-66794d977   1         1         1       13m
~/bitnamischarts/bitnami/metallb$ kubectl logs service/metallb-webhook-service -n metallb-system | grep 'nginx'
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:112","controller":"ServiceReconciler","endpoints":"[]","event":"failed to handle service","level":"error","name":"default/nginx","service":"{\"kind\":\"Service\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"nginx\",\"namespace\":\"default\",\"uid\":\"e770d426-cbf5-4dca-8793-9601b0336df4\",\"resourceVersion\":\"4611\",\"creationTimestamp\":\"2024-05-08T21:42:16Z\",\"annotations\":{\"kubectl.kubernetes.io/last-applied-configuration\":\"{\\\"apiVersion\\\":\\\"v1\\\",\\\"kind\\\":\\\"Service\\\",\\\"metadata\\\":{\\\"annotations\\\":{},\\\"name\\\":\\\"nginx\\\",\\\"namespace\\\":\\\"default\\\"},\\\"spec\\\":{\\\"ports\\\":[{\\\"port\\\":80}],\\\"selector\\\":{\\\"app\\\":\\\"nginx\\\"},\\\"type\\\":\\\"LoadBalancer\\\"}}\\n\"},\"managedFields\":[{\"manager\":\"kubectl-client-side-apply\",\"operation\":\"Update\",\"apiVersion\":\"v1\",\"time\":\"2024-05-08T21:42:16Z\",\"fieldsType\":\"FieldsV1\",\"fieldsV1\":{\"f:metadata\":{\"f:annotations\":{\".\":{},\"f:kubectl.kubernetes.io/last-applied-configuration\":{}}},\"f:spec\":{\"f:allocateLoadBalancerNodePorts\":{},\"f:externalTrafficPolicy\":{},\"f:internalTrafficPolicy\":{},\"f:ports\":{\".\":{},\"k:{\\\"port\\\":80,\\\"protocol\\\":\\\"TCP\\\"}\":{\".\":{},\"f:port\":{},\"f:protocol\":{},\"f:targetPort\":{}}},\"f:selector\":{},\"f:sessionAffinity\":{},\"f:type\":{}}}}]},\"spec\":{\"ports\":[{\"protocol\":\"TCP\",\"port\":80,\"targetPort\":80,\"nodePort\":31329}],\"selector\":{\"app\":\"nginx\"},\"clusterIP\":\"10.43.96.58\",\"clusterIPs\":[\"10.43.96.58\"],\"type\":\"LoadBalancer\",\"sessionAffinity\":\"None\",\"externalTrafficPolicy\":\"Cluster\",\"ipFamilies\":[\"IPv4\"],\"ipFamilyPolicy\":\"SingleStack\",\"allocateLoadBalancerNodePorts\":true,\"internalTrafficPolicy\":\"Cluster\"},\"status\":{\"loadBalancer\":{}}}","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:113","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:16Z"}
~/bitnamischarts/bitnami/metallb$ kubectl logs daemonset.apps/metallb-decoderleco-speaker -n metallb-system | grep 'nginx'
Found 2 pods, using pod/metallb-decoderleco-speaker-9lkwg
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:115","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:115","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:17Z"}
{"caller":"service_controller.go:115","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:17Z"}
~/bitnamischarts/bitnami/metallb$ kubectl logs deployment.apps/metallb-decoderleco-controller -n metallb-system | grep 'nginx'
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"default/nginx","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:112","controller":"ServiceReconciler","endpoints":"[]","event":"failed to handle service","level":"error","name":"default/nginx","service":"{\"kind\":\"Service\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"nginx\",\"namespace\":\"default\",\"uid\":\"e770d426-cbf5-4dca-8793-9601b0336df4\",\"resourceVersion\":\"4611\",\"creationTimestamp\":\"2024-05-08T21:42:16Z\",\"annotations\":{\"kubectl.kubernetes.io/last-applied-configuration\":\"{\\\"apiVersion\\\":\\\"v1\\\",\\\"kind\\\":\\\"Service\\\",\\\"metadata\\\":{\\\"annotations\\\":{},\\\"name\\\":\\\"nginx\\\",\\\"namespace\\\":\\\"default\\\"},\\\"spec\\\":{\\\"ports\\\":[{\\\"port\\\":80}],\\\"selector\\\":{\\\"app\\\":\\\"nginx\\\"},\\\"type\\\":\\\"LoadBalancer\\\"}}\\n\"},\"managedFields\":[{\"manager\":\"kubectl-client-side-apply\",\"operation\":\"Update\",\"apiVersion\":\"v1\",\"time\":\"2024-05-08T21:42:16Z\",\"fieldsType\":\"FieldsV1\",\"fieldsV1\":{\"f:metadata\":{\"f:annotations\":{\".\":{},\"f:kubectl.kubernetes.io/last-applied-configuration\":{}}},\"f:spec\":{\"f:allocateLoadBalancerNodePorts\":{},\"f:externalTrafficPolicy\":{},\"f:internalTrafficPolicy\":{},\"f:ports\":{\".\":{},\"k:{\\\"port\\\":80,\\\"protocol\\\":\\\"TCP\\\"}\":{\".\":{},\"f:port\":{},\"f:protocol\":{},\"f:targetPort\":{}}},\"f:selector\":{},\"f:sessionAffinity\":{},\"f:type\":{}}}}]},\"spec\":{\"ports\":[{\"protocol\":\"TCP\",\"port\":80,\"targetPort\":80,\"nodePort\":31329}],\"selector\":{\"app\":\"nginx\"},\"clusterIP\":\"10.43.96.58\",\"clusterIPs\":[\"10.43.96.58\"],\"type\":\"LoadBalancer\",\"sessionAffinity\":\"None\",\"externalTrafficPolicy\":\"Cluster\",\"ipFamilies\":[\"IPv4\"],\"ipFamilyPolicy\":\"SingleStack\",\"allocateLoadBalancerNodePorts\":true,\"internalTrafficPolicy\":\"Cluster\"},\"status\":{\"loadBalancer\":{}}}","ts":"2024-05-08T21:42:16Z"}
{"caller":"service_controller.go:113","controller":"ServiceReconciler","end reconcile":"default/nginx","level":"info","ts":"2024-05-08T21:42:16Z"}
~/bitnamischarts/bitnami/metallb$ kubectl describe service/nginx
Name:                     nginx
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=nginx
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.96.58
IPs:                      10.43.96.58
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31329/TCP
Endpoints:                10.42.1.11:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
~/bitnamischarts/bitnami/metallb$ kubectl describe cm/metallb-decoderleco-config -n metallb-system
Name:         metallb-decoderleco-config
Namespace:    metallb-system
Labels:       app.kubernetes.io/instance=metallb-decoderleco
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=metallb
              app.kubernetes.io/version=0.14.5
              helm.sh/chart=metallb-6.1.4
Annotations:  meta.helm.sh/release-name: metallb-decoderleco
              meta.helm.sh/release-namespace: metallb-system

Data
====
config:
----
address-pools:
- name: default
  protocol: layer2
  addresses:
  - 172.19.0.240/29


BinaryData
====

Events:  <none>

```


I see only one question left to check:

Ok, my k3d cluster is indeed using a docker network, is it really the one I created and passed to `k3d create` command with the `--network` option (`K3D_NET_NAME=decoderleco_knet`): 
* where i can include `172.19.0.240/29` as subnet
* the one I created before creating the k3d cluster has the below properties:

```bash
~/bitnamischarts/bitnami/metallb$
export K3D_NET_CIDR_BLOCK=$(docker network inspect ${K3D_NET_NAME} | jq '. [0].IPAM.Config[0].Subnet' | tr -d '"')

echo "K3D_NET_CIDR_BLOCK=[${K3D_NET_CIDR_BLOCK}]"

export K3D_NET_BASE_ADDR=${K3D_NET_CIDR_BLOCK%???}

export K3D_NET_FIRST_ADDR=$(echo $K3D_NET_CIDR_BLOCK | awk -F'.' '{print $1,$2,$3,240}' OFS='.')

export K3D_NET_RANGE="$K3D_NET_FIRST_ADDR/29"


echo "K3D_NET_BASE_ADDR=[${K3D_NET_BASE_ADDR}]"
echo "K3D_NET_FIRST_ADDR=[${K3D_NET_FIRST_ADDR}]"
echo "K3D_NET_RANGE=[${K3D_NET_RANGE}]"
K3D_NET_CIDR_BLOCK=[172.19.0.0/16]
K3D_NET_BASE_ADDR=[172.19.0.0]
K3D_NET_FIRST_ADDR=[172.19.0.240]
K3D_NET_RANGE=[172.19.0.240/29]
~/bitnamischarts/bitnami/metallb$ echo "K3D_NET_NAME=[${K3D_NET_NAME}]"
K3D_NET_NAME=[decoderleco_knet]
```

LEt's check if the `decoderleco_knet` docker network is indeed the one in use by my k3d cluster:

```bash
~/bitnamischarts/bitnami/metallb$ docker ps -a
CONTAINER ID   IMAGE                                          COMMAND                  CREATED       STATUS       PORTS                              NAMES
bc8c33a34919   rancher/k3s:v1.28.8-k3s1                       "/bin/k3d-entrypoint…"   3 hours ago   Up 3 hours                                      k3d-k8-lab-agent-0
22d3fee8221b   rancher/k3s:v1.28.8-k3s1                       "/bin/k3d-entrypoint…"   3 hours ago   Up 3 hours   0.0.0.0:6550->6443/tcp             k3d-k8-lab-server-0
70129a325f64   decoderleco/deno-jupyter:0.0.1-alpha-aarch64   "/run/start.debug.sh"    3 hours ago   Up 3 hours   0.0.0.0:8888->8888/tcp             jupyterlab-jupyter_deno_aarch64-1
f29a8d9e1349   mongodb/mongodb-community-server:6.0-ubi8      "python3 /usr/local/…"   3 hours ago   Up 3 hours   0.0.0.0:27017->27017/tcp           jupyterlab-mongodb-1
bf991f9148cf   quay.io/minio/minio                            "/usr/bin/docker-ent…"   3 hours ago   Up 3 hours   0.0.0.0:9000-9001->9000-9001/tcp   minio
~/bitnamischarts/bitnami/metallb$ docker inspect k3d-k8-lab-server-0 -f "{{json .NetworkSettings.Networks }}"
{"decoderleco_knet":{"IPAMConfig":null,"Links":null,"Aliases":null,"MacAddress":"02:42:ac:13:00:02","NetworkID":"b619a0cfe5fd1dd595f385c803f3c720f79b299b0da5039c63aec45036554015","EndpointID":"3af8f4731f8aaed75fd1fa4d4b0ae8ab62634c67e30e58bbfa6d7e3a99c7d9d2","Gateway":"172.19.0.1","IPAddress":"172.19.0.2","IPPrefixLen":16,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"DriverOpts":null,"DNSNames":["k3d-k8-lab-server-0","22d3fee8221b"]}}
~/bitnamischarts/bitnami/metallb$ docker inspect k3d-k8-lab-agent-0 -f "{{json .NetworkSettings.Networks }}"
{"decoderleco_knet":{"IPAMConfig":null,"Links":null,"Aliases":null,"MacAddress":"02:42:ac:13:00:03","NetworkID":"b619a0cfe5fd1dd595f385c803f3c720f79b299b0da5039c63aec45036554015","EndpointID":"50c454f70701c63bc57e96c705a2941be705717885d75417fd9f04518a59335a","Gateway":"172.19.0.1","IPAddress":"172.19.0.3","IPPrefixLen":16,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"DriverOpts":null,"DNSNames":["k3d-k8-lab-agent-0","bc8c33a34919"]}}
~/bitnamischarts/bitnami/metallb$

```

Well actually yes it's as expected... SO Now i'm running out of any idea to troubleshoot fruther the issue, even metallb logs themselves are very poor in exeplanations...

Maybe only one left idea: running metallb with DEBUG log level...?


ANother thing I can try and check, its a networking test that I have to do from within inside the docker network:
https://metallb.universe.tf/troubleshooting/#check-if-the-arp-requests-reach-the-node

actually i think i am in this case : https://metallb.universe.tf/troubleshooting/#metallb-says-it-advertises-the-service-but-reaching-the-service-does-not-work

so there i will have to do multple netqworking tests, L2 layer level and understandng fully how to test ARP protocol.

https://www.youtube.com/watch?v=cn8Zxh9bPio

https://www.google.com/search?q=linux+tutorial+troubleshooting+the+arp+protocol&sca_esv=e366935364740875&sca_upv=1&ei=X_47Zv-uNtWKkdUP3cqXkAk&ved=0ahUKEwi_2srxjv-FAxVVRaQEHV3lBZIQ4dUDCBA&uact=5&oq=linux+tutorial+troubleshooting+the+arp+protocol&gs_lp=Egxnd3Mtd2l6LXNlcnAiL2xpbnV4IHR1dG9yaWFsIHRyb3VibGVzaG9vdGluZyB0aGUgYXJwIHByb3RvY29sMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHMgoQABiwAxjWBBhHSLoJUABYAHABeAGQAQCYAQCgAQCqAQC4AQPIAQCYAgGgAgeYAwCIBgGQBgiSBwExoAcA&sclient=gws-wiz-serp

https://www.redhat.com/sysadmin/beginners-guide-network-troubleshooting-linux



We can check the entries in our ARP table with the ip neighbor command:

```bash
# ip neighbor show
192.168.122.1 dev eth0 lladdr 52:54:00:11:23:84 REACHABLE
```

Note that the gateway’s MAC address is populated (we’ll talk more about how to find your gateway in the next section). If there was a problem with ARP, then we would see a resolution failure:

```bash
# ip neighbor show
192.168.122.1 dev eth0 FAILED
```

Another common use of the ip neighbor command involves manipulating the ARP table. Imagine that your networking team just replaced the upstream router (which is your server’s default gateway). The MAC address may have changed as well since MAC addresses are hardware addresses that are assigned at the factory.

https://www.ithands-on.com/2021/08/linux-101-troubleshooting-arp.html



### Troubleshooting the ARP inside docker for the k3d nodes

Okay, so now we are going to explicitly put in clear words the problem, and say as prcisely as possible what test we are going to run, before running any command.

* we are going to run arp troubleshooting commands in a given docker network: so we will need to run thse commands from within inside a container, in which we have installed all the tools we'll need to troubleshoot the network.
* this container we are going to run the troubleshooting commands in, are going to be:
  * the 2 docker containers created by `k3d`, namely: `k3d-k8-lab-server-0`, and `k3d-k8-lab-agent-0`.
  * anoher third container that i'm going to create with just a docker compose, that container will be connected to the same docker network as the 2 containers of the k3d cluster. I'll call that container the troubleshooter container.
* we are also going to run arp command from 2 kubernetes pods within the k3d cluster:
  * Indeed, `metallb` is made of 2 components:
    * The kubernetes `controller` is in charge of assigning IPs to the services
    * The kubernetes speakers are in charge of announcing the services via L2 or BGP
  * So the 2 pods i will create:
    * will both have only on container, based upon the same image as our troubleshooter docker compose
    * one of the pods will impersonate the speaker: to perform, as much as possible, the same arp operations than the actual metallb speaker
    * one of the pods will impersonate the controller: to perform, as much as possible, the same arp operations than the actual metallb controller

## Troubleshooter commands

### In docker-compose version

#### Test the (Physical link) layer 1

```bash

cd ~/packman/oracle/post_install/kubernetes/k3d-metallb/

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip link show"

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -br link show"

```

To test if layer 1 (physical layer) is fine (the physical link is established, up n running):

```bash
docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -s link show eth0@if66"

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -s link show eth0"


```

Gives as example output :

```bash
~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -s link show eth0"     WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
65: eth0@if66: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default
    link/ether 02:42:ac:14:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    RX:  bytes packets errors dropped  missed   mcast
          1576      20      0       0       0       0
    TX:  bytes packets errors dropped carrier collsns
             0       0      0       0       0       0

```

Its a bit like a ping, where 20 packets are sent for the test.

I could also run the `ethtool eth0` comman in the container, and i got the following interesting result:

```bash
~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ethtool eth0"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
netlink error: Operation not permitted
Settings for eth0:
        Supported ports: [  ]
        Supported link modes:   Not reported
        Supported pause frame use: No
        Supports auto-negotiation: No
        Supported FEC modes: Not reported
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        Advertised FEC modes: Not reported
        Speed: 10000Mb/s
        Duplex: Full
        Auto-negotiation: off
        Port: Twisted Pair
        PHYAD: 0
        Transceiver: internal
        MDI-X: Unknown
        Link detected: yes

```

#### ARP Protocol tests

* I check the entries in our ARP table with the ip neighbor command, and I get:

```bash
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "cat /proc/net/arp"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
IP address       HW type     Flags       HW address            Mask     Device
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$

```

Now to start with, obviously the ARP cache is empty in my troubleshooter container. AS you can see below, its IP address is `172.20.0.2`

And here is how i got the IP address, in the docker network, of the 2 containers of the k3d kubernetes cluster:

```bash
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker inspect k3d-k8-lab-server-0 -f "{{json .NetworkSettings.Networks }}" | jq .
{
  "decoderleco_knet": {
    "IPAMConfig": null,
    "Links": null,
    "Aliases": null,
    "MacAddress": "02:42:ac:13:00:02",
    "NetworkID": "527594a23e5d437398a6f821fd61d6c78287f7885b45de3cba19e99abe53a267",
    "EndpointID": "0cc71ea8885048e252d1fe26630dc8af9a5105dda6102dc1dc3b8e1b78b3b71f",
    "Gateway": "172.19.0.1",
    "IPAddress": "172.19.0.2",
    "IPPrefixLen": 16,
    "IPv6Gateway": "",
    "GlobalIPv6Address": "",
    "GlobalIPv6PrefixLen": 0,
    "DriverOpts": null,
    "DNSNames": [
      "k3d-k8-lab-server-0",
      "6aacfb0dacf0"
    ]
  }
}
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker inspect k3d-k8-lab-agent-0 -f "{{json .NetworkSettings.Networks }}" | jq .
{
  "decoderleco_knet": {
    "IPAMConfig": null,
    "Links": null,
    "Aliases": null,
    "MacAddress": "02:42:ac:13:00:03",
    "NetworkID": "527594a23e5d437398a6f821fd61d6c78287f7885b45de3cba19e99abe53a267",
    "EndpointID": "223ecbd836191ad59641ecabe7eafc7765ca53da2f8007cc82d938b8d877507f",
    "Gateway": "172.19.0.1",
    "IPAddress": "172.19.0.3",
    "IPPrefixLen": 16,
    "IPv6Gateway": "",
    "GlobalIPv6Address": "",
    "GlobalIPv6PrefixLen": 0,
    "DriverOpts": null,
    "DNSNames": [
      "k3d-k8-lab-agent-0",
      "b6d39531e742"
    ]
  }
}
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker inspect k3d-metallb-k3d_net_plumber-1 -f "{{json .NetworkSettings.Networks }}" | jq .
{
  "k3d-metallb_decoderleco_knet": {
    "IPAMConfig": {},
    "Links": null,
    "Aliases": [
      "k3d-metallb-k3d_net_plumber-1",
      "k3d_net_plumber",
      "k3d_net_plumber.dataviz_poc.io",
      "k3d_net_plumber.io"
    ],
    "MacAddress": "02:42:ac:14:00:02",
    "NetworkID": "1abfc26a47c94de95a29377e532de04655ad0a40cd04953a9b115c732a4fb78b",
    "EndpointID": "0cbd1399ab9880bdfcea06cfbf910d6b7112516fec2d9d0809f7904ae623071a",
    "Gateway": "172.20.0.1",
    "IPAddress": "172.20.0.2",
    "IPPrefixLen": 16,
    "IPv6Gateway": "",
    "GlobalIPv6Address": "",
    "GlobalIPv6PrefixLen": 0,
    "DriverOpts": null,
    "DNSNames": [
      "k3d-metallb-k3d_net_plumber-1",
      "k3d_net_plumber",
      "k3d_net_plumber.dataviz_poc.io",
      "k3d_net_plumber.io",
      "e213716c3d8d"
    ]
  }
}
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$


```

From the above outpout of docker inspect command for the 3 containers, we get those informations :

* container `k3d-k8-lab-server-0` has:
  * IP Addresss: `172.19.0.2`
  * MAC Addresss: `02:42:ac:13:00:02`
  * Gateway: `172.19.0.1`
* container `k3d-k8-lab-agent-0` has:
  * IP Addresss: `172.19.0.3`
  * MAC Addresss: `02:42:ac:13:00:03`
  * Gateway: `172.19.0.1`
* container `k3d-metallb-k3d_net_plumber-1` is in the docker network named `k3d-metallb_decoderleco_knet` (that's the troubleshooter ) has:
  * IP Addresss: `172.20.0.2`
  * MAC Addresss: `02:42:ac:14:00:02`
  * Gateway: `172.20.0.1`

So here I saw something:

* My docker compose created a network named `k3d-metallb_decoderleco_knet`,
* and put my `k3d-metallb-k3d_net_plumber-1` container int hat same network
* while what i wanted is that my container ends up attached to the `decoderleco_knet` docker network.

To fix that, I ran :

```bash
docker inspect k3d-k8-lab-server-0 -f "{{json .NetworkSettings.Networks }}" | jq .
docker inspect k3d-k8-lab-agent-0 -f "{{json .NetworkSettings.Networks }}" | jq .
docker inspect k3d-metallb-k3d_net_plumber-1 -f "{{json .NetworkSettings.Networks }}" | jq .

docker network connect decoderleco_knet k3d-metallb-k3d_net_plumber-1
```

And I run again my test commands:

```bash
export K3D_NET_NAME="decoderleco_knet"

docker inspect k3d-k8-lab-server-0 -f "{{json .NetworkSettings.Networks }}" | jq .
docker inspect k3d-k8-lab-agent-0 -f "{{json .NetworkSettings.Networks }}" | jq .
docker inspect k3d-metallb-k3d_net_plumber-1 -f "{{json .NetworkSettings.Networks }}" | jq .${K3D_NET_NAME}

export K3D_SERVER_IPADDR=$(docker inspect k3d-k8-lab-server-0 -f "{{json .NetworkSettings.Networks.${K3D_NET_NAME}.IPAddress }}" | awk -F '"' '{print $2}')

export K3D_AGENT_IPADDR=$(docker inspect k3d-k8-lab-agent-0 -f "{{json .NetworkSettings.Networks.${K3D_NET_NAME}.IPAddress }}" | awk -F '"' '{print $2}')

echo "K3D_SERVER_IPADDR=[${K3D_SERVER_IPADDR}]"
echo "K3D_AGENT_IPADDR=[${K3D_AGENT_IPADDR}]"

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -s link show eth0"
docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ethtool eth0"
docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "cat /proc/net/arp"

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ping -c 4 ${K3D_SERVER_IPADDR}"

docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ping -c 4 ${K3D_AGENT_IPADDR}"


docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "cat /proc/net/arp"

```

And I get now very nteresting results, showing that my truble shooter does sucessfully get ARP cache populated with MAC Adresses and IP address entries:

```bash
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip -s link show eth0"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
65: eth0@if66: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default
    link/ether 02:42:ac:14:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    RX:  bytes packets errors dropped  missed   mcast
          1618      21      0       0       0       0
    TX:  bytes packets errors dropped carrier collsns
           434       5      0       0       0       0
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ethtool eth0"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
netlink error: Operation not permitted
Settings for eth0:
        Supported ports: [  ]
        Supported link modes:   Not reported
        Supported pause frame use: No
        Supports auto-negotiation: No
        Supported FEC modes: Not reported
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        Advertised FEC modes: Not reported
        Speed: 10000Mb/s
        Duplex: Full
        Auto-negotiation: off
        Port: Twisted Pair
        PHYAD: 0
        Transceiver: internal
        MDI-X: Unknown
        Link detected: yes
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
172.20.0.1 dev eth0 lladdr 02:42:29:6f:90:8d STALE
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "cat /proc/net/arp"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
IP address       HW type     Flags       HW address            Mask     Device
172.20.0.1       0x1         0x2         02:42:29:6f:90:8d     *        eth0
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ping -c 4 ${K3D_SERVER_IPADDR}"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
PING 172.19.0.2 (172.19.0.2) 56(84) bytes of data.
64 bytes from 172.19.0.2: icmp_seq=1 ttl=64 time=0.620 ms
64 bytes from 172.19.0.2: icmp_seq=2 ttl=64 time=0.080 ms
64 bytes from 172.19.0.2: icmp_seq=3 ttl=64 time=0.083 ms
64 bytes from 172.19.0.2: icmp_seq=4 ttl=64 time=0.083 ms

--- 172.19.0.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3075ms
rtt min/avg/max/mdev = 0.080/0.216/0.620/0.232 ms
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
172.20.0.1 dev eth0 lladdr 02:42:29:6f:90:8d STALE
172.19.0.2 dev eth1 lladdr 02:42:ac:13:00:02 REACHABLE
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ping -c 4 ${K3D_AGENT_IPADDR}"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
PING 172.19.0.3 (172.19.0.3) 56(84) bytes of data.
64 bytes from 172.19.0.3: icmp_seq=1 ttl=64 time=0.185 ms
64 bytes from 172.19.0.3: icmp_seq=2 ttl=64 time=0.076 ms
64 bytes from 172.19.0.3: icmp_seq=3 ttl=64 time=0.072 ms
64 bytes from 172.19.0.3: icmp_seq=4 ttl=64 time=0.086 ms

--- 172.19.0.3 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3068ms
rtt min/avg/max/mdev = 0.072/0.104/0.185/0.046 ms
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$ docker-compose -f ./troubleshooter.yml exec -T k3d_net_plumber bash -c "ip neighbor show"
WARN[0000] The "K3D_NET_FIRST_ADDR" variable is not set. Defaulting to a blank string.
WARN[0000] The "K3D_NET_RANGE" variable is not set. Defaulting to a blank string.
WARN[0000] /home/ubuntu/packman/oracle/post_install/kubernetes/k3d-metallb/troubleshooter.yml: `version` is obsolete
172.20.0.1 dev eth0 lladdr 02:42:29:6f:90:8d STALE
172.19.0.2 dev eth1 lladdr 02:42:ac:13:00:02 STALE
172.19.0.3 dev eth1 lladdr 02:42:ac:13:00:03 REACHABLE
ubuntu@myserver:~/packman/oracle/post_install/kubernetes/k3d-metallb$

```

But yet now, I still get this for my `nginx` deployment in my `k3d` cluster (metallb fails to allocate IPAddress to the NGINX deployed LoadBalancer):

```bash
kubectl get all

kubectl get all -n metallb-system

kubectl logs service/metallb-webhook-service -n metallb-system | grep 'nginx'

kubectl logs deployment.apps/metallb-decoderleco-controller -n metallb-system | grep 'nginx'

kubectl describe service/nginx

kubectl describe cm/metallb-decoderleco-config -n metallb-system

```

The tests I ran with the docker-compose troubleshootershow that in my server on oracle, ARP PRotocol work perfectely fine as expected for network connectivity between docker containers.

So next, I will have to run pretty much the same kind of ARP tests, from within k3d pods, which will answer to only one question, about the ARP protocol working fine for connectivity between containers within the kubernetes cluster.

But I still have more questions to get an answer to:

* (controller) What exactly are the network operations executed by the Metallb to assign an IP address to the NGINX `Kubernetes` `LoadBalancer` ? To answer that question, I will try and run linux commands which perform the exact same network operations.
* (speaker) What exactly are the network operations executed by the Metallb to broadcast the IP address of the NGINX `Kubernetes` `LoadBalancer` ? To answer that question, I will try and run linux commands which perform the exact same network operations.

## References

* https://forums.docker.com/t/arp-cache-mac-and-docker/68985
* I duely note that:
  * metallb design is at least recently related to the FRRouting software (FRRouting stands for Free Range Routing), a successor of Quaggua, see https://github.com/metallb/frr-k8s and https://frrouting.org/ 
  * metallb most used deployment method is its helm chart, but there exists a Kubernetes operator which does nt seem to have a helm chart yet (MAy 2024), see https://github.com/metallb/metallb-operator
  * All his is really interesting, and advanced topic about kubernetes, and valuable to learn about deep kubernetes networking. Fixing my issue my lead me to completely re-implement 
* I have there an idea i am keen on trying: would it be possible to implement a golang or nodejs software able to provision dynamically a load balancer by an api? If so, then I could implement a kubernetes operator or controller like above to implement my own small metallb. Would be a grat exercize to lern lots about networking and kubernetes at same time. I will then hav my own CRDs.

Before going that deep, I see one other test I can easily do: try and run the exact same tests but inside a simple VirtualBox VM, at home. There I wil have to tkae in consideration the fact that 

## ANNEX What is MetallB ?

MetallB in the Kubernetes Terminology (as of may 2024) is a _**Kubernetes External Load Balancer Provider**_.
The bzlow quote explains briefly, but very clearly actually, how kubernetes standardizes that concept of _**Kubernetes External Load Balancer Provider**_:

* You implement a kubernetes controller in charge of hitting the cloud provider's api to create a Network Load Balancer.
* The cloud provider creates that load balancer, which load balances between the kubernetes cluster nodes
* When the clud provider has finished its work of creating that load balancer by finally assiging one or more IP addresses to the kubernetes cluster nodes, then only the Kubernetes controller grabs the value of that IP address, and assigns it to the Kubernetes Service.
* So basically here I think Metallb here uses (FRRouting?Something else?) to create the load balancer. How to create a load baalncer using FRRouting?
* This article gives many very useful infos on metallb insights, among which it is clear that MEtallb uses FRrouting for the BGP Mode (so I'm not for y case for the ARP case I'm working with for now) <https://www.redhat.com/en/blog/metallb-in-bgp-mode>

#### External load balancer providers

It is important to note that the `datapath` for this functionality is provided by a load balancer external to the Kubernetes cluster.

When the Service type is set to `LoadBalancer`, Kubernetes provides functionality equivalent to type equals `ClusterIP` to pods within the cluster and extends it by programming the (external to Kubernetes) load balancer with entries for the nodes hosting the relevant Kubernetes pods. **The Kubernetes control plane automates the creation of the external load balancer**, health checks (if needed), and packet filtering rules (if needed). **Once the cloud provider allocates an IP address for the load balancer**, the control plane looks up that external IP address and populates it into the Service object.


https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#external-load-balancer-providers
