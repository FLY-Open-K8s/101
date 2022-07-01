### Add grafana repo

```sh
helm repo add grafana https://grafana.github.io/helm-charts

helm repo update
```

### Install loki-stack

```sh
helm -n loki upgrade --install loki grafana/loki-stack --set grafana.enabled=true,prometheus.enabled=true,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false

helm -n loki upgrade --install loki grafana/loki-stack --set grafana.enabled=true,promtail.enabled=true,prometheus.enabled=false,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false,loki.persistence.enabled=false


helm -n loki upgrade --install loki grafana/loki-stack --set grafana.enabled=true,promtail.enabled=true,prometheus.enabled=false,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false,loki.persistence.enabled=true,loki.persistence.storageClassName=default,loki.persistence.size=1Gi

```

安装信息

> 需要提前准备一个sc名为loki

```bash
helm -n loki upgrade --install loki grafana/loki-stack --set grafana.enabled=true,promtail.enabled=true,prometheus.enabled=false,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false,loki.persistence.enabled=true,loki.persistence.storageClassName=default,loki.persistence.size=1Gi

Release "loki" does not exist. Installing it now.
NAME: loki
LAST DEPLOYED: Tue Jun 28 08:25:16 2022
NAMESPACE: loki
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.

See http://docs.grafana.org/features/datasources/loki/ for more detail.
You have new mail.  
```



### If you get the following error, that means your k8s version is too new to install

```
Error: unable to build kubernetes objects from release manifest: [unable to recognize "": no matches for kind "ClusterRole" in version "rbac.authorization.k8s.io/v1beta1", unable to recognize "": no matches for kind "ClusterRoleBinding" in version "rbac.authorization.k8s.io/v1beta1", unable to recognize "": no matches for kind "Role" in version "rbac.authorization.k8s.io/v1beta1", unable to recognize "": no matches for kind "RoleBinding" in version "rbac.authorization.k8s.io/v1beta1"]
```



### 下载 loki-stack

```sh
helm pull grafana/loki-stack
tar -xvf loki-stack-*.tgz
cd loki-stack
```

### Replace all `rbac.authorization.k8s.io/v1beta1` with `rbac.authorization.k8s.io/v1` by 
```sh
grep -rl "rbac.authorization.k8s.io/v1beta1" . | xargs sed -i 's/rbac.authorization.k8s.io\/v1beta1/rbac.authorization.k8s.io\/v1/g'
```

### Install loki locally

```sh
helm upgrade --install loki ./loki-stack --set grafana.enabled=true,prometheus.enabled=true,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false

helm -n loki upgrade --install loki ./loki-stack --set grafana.enabled=true,promtail.enabled=true,prometheus.enabled=false,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false,loki.persistence.enabled=false
```





### Change the grafana service to NodePort type and access it

```sh
kubectl edit svc loki-grafana -oyaml -n default
```

And change ClusterIP type to NodePort.

Login password is in secret `loki-grafana`

```sh
kubectl get secret loki-grafana -oyaml -n default
```

Find admin-password: `xxx`

```sh
echo 'xxx' | base64 -d
```

Then you will get grafana login password, the login username is 'admin' on default.

> Note: `xxx` is the value of key `admin-password` in your yaml.

### Change the grafana service to NodePort type and access it

Login password is in secret `loki-grafana`



### 参考链接

https://grafana.com/docs/loki/latest/storage/