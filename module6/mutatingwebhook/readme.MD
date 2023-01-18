### Clone admission demo

```sh
git clone https://github.com/cncamp/admission-controller-webhook-demo.git
```

### Deploy webhook

```sh
cd admission-controller-webhook-demo/

# 格式转换
find ./ -type f -name "*.sh" -exec dos2unix -k -s -o {} ';'
find ./ -type f -name "*.conf" -exec dos2unix -k -s -o {} ';'
find ./ -type f -name "*.yml" -exec dos2unix -k -s -o {} ';'

# 赋予权限
chmod 777 ./deployment/generate-keys.sh
chmod 777 ./deploy.sh

# 部署
./deploy.sh

# 部署过程
[root@master-1 admission-controller-webhook-demo]# ./deploy.sh 
Generating TLS keys ...
Generating a 2048 bit RSA private key
...+++
.............................+++
writing new private key to 'ca.key'
-----
Generating RSA private key, 2048 bit long modulus
......................+++
...+++
e is 65537 (0x10001)
Signature ok
subject=/CN=webhook-server.webhook-demo.svc
Getting CA Private Key
Creating Kubernetes objects ...
namespace/webhook-demo created
secret/webhook-server-tls created
deployment.apps/webhook-server created
service/webhook-server created
mutatingwebhookconfiguration.admissionregistration.k8s.io/demo-webhook created
The webhook server has been deployed and configured!

[root@master-1 /]# kubectl get deployment.apps/webhook-server -n webhook-demo
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
webhook-server   1/1     1            1           2m58s
[root@master-1 /]# kubectl get po -n webhook-demo
NAME                              READY   STATUS    RESTARTS   AGE
webhook-server-7d9f9fcf58-dd26q   1/1     Running   0          2m59s

```

### 问题

**Error creating: Internal error occurred: failed calling webhook "webhook-server.webhook-demo.svc": failed to call webhook: Post "https://webhook-server.webhook-demo.svc:443/mutate?timeout=10s": dial tcp 10.97.150.54:443: connect: connection refused**

```bash

curl -H "Content-Type: application/json" -X POST  "https://webhook-server.webhook-demo.svc:443/mutate?timeout=10s"

参数 内容
-H 请求头
-d POST内容
-X 请求协议
```



[root@master-1 admission-controller-webhook-demo]# kubectl create -f examples/pod-with-defaults.yaml
Error from server (InternalError): error when creating "examples/pod-with-defaults.yaml": Internal error occurred: failed calling webhook "webhook-server.webhook-demo.svc": failed to call webhook: Post "https://webhook-server.webhook-demo.svc:443/mutate?timeout=10s": x509: certificate has expired or is not yet valid: current time 2022-10-30T10:37:21Z is before 2022-10-30T17:38:53Z



**Failed to create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "adf0a28546ff5875299f15a909b0394721ff93f196ced9c68c2fc18f58ab2b3f" network for pod "webhook-server-7d9f9fcf58-wjbdp": networkPlugin cni failed to set up pod "webhook-server-7d9f9fcf58-wjbdp_webhook-demo" network: error getting ClusterInformation: connection is unauthorized: Unauthorized, failed to clean up sandbox container "adf0a28546ff5875299f15a909b0394721ff93f196ced9c68c2fc18f58ab2b3f" network for pod "webhook-server-7d9f9fcf58-wjbdp": networkPlugin cni failed to teardown pod "webhook-server-7d9f9fcf58-wjbdp_webhook-demo" network: error getting ClusterInformation: connection is unauthorized: Unauthorized]**



Oct 30 19:56:39 master-1 kubelet[1064]: E1030 19:56:39.582563    1064 pod_workers.go:765] "Error syncing pod, skipping" err="failed to \"CreatePodSandbox\" for \"kube-controller-manager-master-1_kube-system(027e81027a9e84c126b52208f51933dd)\" with CreatePodSandboxError: \"Failed to create sandbox for pod \\\"kube-controller-manager-master-1_kube-system(027e81027a9e84c126b52208f51933dd)\\\": rpc error: code = Unknown desc = failed to create a sandbox for pod \\\"kube-controller-manager-master-1\\\": Error response from daemon: Conflict. The container name \\\"/k8s_POD_kube-controller-manager-master-1_kube-system_027e81027a9e84c126b52208f51933dd_29\\\" is already in use by container \\\"f6665623f48f9c5d847ccd7eb54266358ecc6e94b2a85c09795e1dd69de541fa\\\". You have to remove (or rename) that container to be able to reuse that name.\"" pod="kube-system/kube-controller-manager-master-1" podUID=027e81027a9e84c126b52208f51933dd

### Check webhook status

```sh
# mutatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# 
kubectl get deployment.apps/webhook-server -n webhook-demo
kubectl get po -n webhook-demo
```

### Create demo pod and verify

```sh
kubectl create -f examples/pod-with-defaults.yaml
kubectl get po  pod-with-defaults -oyaml
kubectl logs -f pod-with-defaults
```



### 环境清理

```bash
kubectl create -f examples/pod-with-defaults.yaml
kubectl delete -n webhook-demo secrets webhook-server-tls
kubectl delete ns webhook-demo
```





### More details

https://github.com/cncamp/admission-controller-webhook-demo/blob/main/README.md





ks exec -it kube-apiserver-node1--kube-apiserver-h