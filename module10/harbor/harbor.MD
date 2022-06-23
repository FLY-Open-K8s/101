## Helm3安装

```bash
# 根据操作系统去获取最新二进制安装包https://github.com/helm/helm/releases       
wget https://get.helm.sh/helm-v3.3.1-linux-amd64.tar.gz       
# 由于helm包在国外,我通过ss拉到了腾讯云cos,国内可通过以下地址访问:https://download.osichina.net/tools/k8s/helm/helm-v3.3.1-linux-amd64.tar.gz       
tar -zxvf helm-v3.3.1-linux-amd64.tar.gz       
cp linux-amd64/helm /usr/local/bin/
```

> helm其他安装可参考官方网站: https://helm.sh/docs/intro/install/
>
> 注意: helm 客户端需要下载到安装了 kubectl 并且能执行能正常通过 kubectl 操作 kubernetes 的服务器上, 否则 helm 将不可用

### 配置repo

```bash
helm repo add  elastic    https://helm.elastic.co       
helm repo add  gitlab     https://charts.gitlab.io       
helm repo add  harbor     https://helm.goharbor.io       
helm repo add  bitnami    https://charts.bitnami.com/bitnami       
helm repo add  incubator  https://kubernetes-charts-incubator.storage.googleapis.com       
helm repo add  stable     https://kubernetes-charts.storage.googleapis.com       
# 添加国内仓库       
helm repo add stable http://mirror.azure.cn/kubernetes/charts       
helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts       
helm repo update       
helm repo list       
```

### Download harbor helm chart

```sh
helm repo add harbor https://helm.goharbor.io
helm fetch harbor/harbor --untar
kubectl create ns harbor
```

### Update values.yaml

```sh
vi .harbor/values.yaml
```

And change:

```yaml
expose:
  type: nodePort
tls:
  commonName: 'core.harbor.domain'

persistence:
  enabled: false
```

### Install helm chart

```sh
helm install harbor ./harbor -n harbor
```

### Wait for all pod being ready and access harbor portal

验证安装

```bash
kubectl get deployment -n harbor
# 查看 ingress
kubectl get ingress -n harbor
```

访问harbor portal

```bash
# NodePort方式，默认http的监听端口30002，https是30003
https://宿主机IP:30003
# 默认用户信息
admin/Harbor12345
```

### Download repository certs from

```sh
https://192.168.34.2:30003/harbor/projects/1/repositories
# 进入library项目的镜像仓库部分,下载注册证书（ca.crt）
```

![image-20220621205502327](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202206212055525.png)

### Copy the downloaded ca.crt to vm docker certs configuration folder

```sh
mkdir -p /etc/docker/certs.d/core.harbor.domain
# copy the ca.crt to this folder
systemctl restart docker
```

### Edit /etc/hosts to map core.harbor.domain to harbor svc clusterip

```sh
# 查看harbor的svc服务信息
➜  ~ kubectl get svc -n harbor
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
harbor                 NodePort    10.104.102.203   <none>        80:30002/TCP,443:30003/TCP,4443:30004/TCP   73m

You have new mail.   
# 在 /etc/hosts 中添加 harbor的svc的CLUSTER-IP
10.104.102.203 core.harbor.domain
```

### Docker login

```sh
docker login -u admin -p Harbor12345 core.harbor.domain
# 输出信息
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

### Docker tag a image to core.harbor.domain and push it and you will see it in harbor portal

```bash
# 镜像打TAG
docker tag pause:3.2 core.harbor.domain/library/pause:3.2
# 镜像推送
docker push core.harbor.domain/library/pause:3.2 
# 镜像推送信息
The push refers to repository [core.harbor.domain/library/pause]
ba0dae6243cc: Pushed 
3.2: digest: sha256:4a1c4b21597c1b4415bdbecb28a3296c6b5e23ca4f9feeb599860a1dac6a0108 size: 526
```

![image-20220621213413711](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202206212134842.png)

### Check repositories and blobs

```sh
kubectl exec -it harbor-registry-7d686859d7-xs5nv -n harbor bash
ls -la /storage/docker/registry/v2/repositories/
ls -la /storage/docker/registry/v2/blobs
```

### Database operator

```sh
kubectl exec -it harbor-database-0 -n harbor -- bash
psql -U postgres -d postgres -h 127.0.0.1 -p 5432
\c registry
select * from harbor_user;
\dt
```

### 异常问题

```bash
#docker login -u admin -p Harbor12345 core.harbor.domain
WARNING!Using --password via the CLI is insecure.Use --password-stdin.
INFO[0000]Error logging in to endpoint,trying next endpoint error="Get \"https://core.harbor.domain/v2/":
x509:certificate is valid for core.harbor.domai,not core.harbor.domain"
Get "https://core.harbor.domain/v2/":x509:certificate is valid for core.harbor.domai,not core.harbor.domai
```

### **1、Error response from daemon: Get https://hub.7d.com/v2/: x509: certificate signed by unknown authorit**

需要到 `docker.service` 中修改下参数就可以了

修改 `/usr/lib/systemd/system/docker.service` 配置：

```bash
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
```

重启docker：

```bash
## 守护进程重启
sudo systemctl daemon-reload
## 重启docker服务
sudo systemctl restart docker
```

### **2、413 Request Entity Too Large**

```bash
$ docker push hub.7d.com/mall_repo/mall-portal:1.0
The push refers to repository [hub.7d.com/mall_repo/mall-portal]
5a8f64cc7f4c: Pushing [==================================================>]  73.98MB/73.98MB
35c20f26d188: Layer already exists 
c3fe59dd9556: Preparing 
6ed1a81ba5b6: Layer already exists 
a3483ce177ce: Layer already exists 
ce6c8756685b: Waiting 
30339f20ced0: Waiting 
0eb22bfb707d: Waiting 
a2ae92ffcd29: Waiting 
error parsing HTTP 413 response body: invalid character '<' looking for beginning of value: "<html>\r\n<head><title>413 Request Entity Too Large</title></head>\r\n<body>\r\n<center><h1>413 Request Entity Too Large</h1></center>\r\n<hr><center>nginx/1.17.3</center>\r\n</body>\r\n</html>\r\n"
```

解决办法是自定义参数文件增加：

```bash
  ingress:
    hosts:
      ### 配置 Harbor 的访问域名，需要注意的是配置 notary 域名要和 core 处第一个单词外，其余保持一致
      core: hub.7d.com
      notary: notary.7d.com
    controller: default
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      #### 如果是 traefik ingress，则按下面配置：
#      kubernetes.io/ingress.class: "traefik"
#      traefik.ingress.kubernetes.io/router.tls: 'true'
#      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      #### 如果是 nginx ingress，则按下面配置：
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      # 增加 Nignx配置，放开限制：A
      nginx.org/client-max-body-size: "0"
```

示例源码：

- https://github.com/zuozewei/blog-example/tree/master/Kubernetes/k8s-harbor

### 参考链接

https://goharbor.io/docs/2.5.0/install-config/harbor-ha-helm/
https://blog.z0ukun.com/?p=3597
https://cloud.tencent.com/developer/article/1754686