### Install ingress controller

```sh
kubectl create -f nginx-ingress-deployment.yaml
```

#### 安装结果查看

```bash
kubectl get all -n ingress-nginx
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create--1-llcsg     0/1     Completed   0          117s
pod/ingress-nginx-admission-patch--1-9h7sn      0/1     Completed   0          117s
pod/ingress-nginx-controller-5ccb4b77c6-n79dw   1/1     Running     0          117s

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.104.128.135   <none>        80:31337/TCP,443:32160/TCP   118s
service/ingress-nginx-controller-admission   ClusterIP   10.98.155.162    <none>        443/TCP                      118s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           118s

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-5ccb4b77c6   1         1         1       118s

NAME                                       COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   1/1           5s         117s
job.batch/ingress-nginx-admission-patch    1/1           5s         117s
```

### Generate key-cert

```sh
# use openssl (version >= 1.1.1f) on Linux, e.g. Ubuntu 20.04
# don't run on macOS, which is using LibreSSL
# instead, you can `brew install openssl` on macOS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=cncamp.com/O=cncamp" -addext "subjectAltName = DNS:cncamp.com"
```

#### Centos升级OpenSSL版本

> centos7默认openssl版本为1.0.2，安装emqx的mqtt框架时会发生Kernel pid terminated报错，无法启动，所以需要升级openssl版本

**1.查看openssl版本**

```undefined
openssl version
```

**2.下载openssl**

```bash
wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz --no-check-certificate
```

**3.解压**

```css
tar -zxvf openssl-1.1.1l.tar.gz
```

**4.进入目录**

```css
cd openssl-1.1.1l
```

**5.编译安装**

```bash
./config --prefix=/usr/local/openssl   #如果此步骤报错,需要安装perl以及gcc包

make && make install
```

**6.创建软连接**

```bash
mv /usr/bin/openssl /usr/bin/openssl.bak

ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl

echo "/usr/local/openssl/lib" >> /etc/ld.so.conf

ldconfig -v
```

**7.最后查看版本是否成功**

```bash
openssl version
# OpenSSL 1.1.1l  24 Aug 2021
```

### Create secret

```sh
kubectl create secret tls cncamp-tls --cert=./tls.crt --key=./tls.key
```

### Create a ingress

```sh
kubectl create -f ingress.yaml
```

### Test the result

```sh
# 通过Ingress入口访问--service/ingress-nginx-controller的IP
curl -H "Host: cncamp.com" https://10.104.128.135 -v -k

# 输出信息
* About to connect() to 10.104.128.135 port 443 (#0)
*   Trying 10.104.128.135...
* Connected to 10.104.128.135 (10.104.128.135) port 443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
* skipping SSL peer certificate verification
* SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
* Server certificate:
* 	subject: CN=Kubernetes Ingress Controller Fake Certificate,O=Acme Co
* 	start date: Jun 20 00:30:21 2022 GMT
* 	expire date: Jun 20 00:30:21 2023 GMT
* 	common name: Kubernetes Ingress Controller Fake Certificate
* 	issuer: CN=Kubernetes Ingress Controller Fake Certificate,O=Acme Co
> GET / HTTP/1.1
> User-Agent: curl/7.29.0
> Accept: */*
> Host: cncamp.com
> 
< HTTP/1.1 200 OK
< Date: Mon, 20 Jun 2022 01:25:26 GMT
< Content-Type: text/html
< Content-Length: 612
< Connection: keep-alive
< Last-Modified: Tue, 04 Dec 2018 14:44:49 GMT
< ETag: "5c0692e1-264"
< Accept-Ranges: bytes
< Strict-Transport-Security: max-age=15724800; includeSubDomains
< 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
* Connection #0 to host 10.104.128.135 left intact
```

### 浏览器访问

#### ingress，使用http方式

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-http
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # 若还想使用http协议，则可以在NGINX配置映射中，使用全局禁用ssl-redirect: "false"。
    # 方式一-----全局设置：在nginx-ingress-controller对应的config-map中，配置ssl-redirect=false
    # 或在每个应用服务的Ingress.yaml中，添加注解nginx.ingress.kubernetes.io/ssl-redirect: "false"。
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - host: www.flynginx.com
      http:
        paths:
          - path: "/"
            pathType: Prefix
            backend:
              service:
                name: nginx-svc
                port:
                  number: 80
```

#### 本地浏览器，如果是windows修改host 添加域名

```bash
# C:\Windows\System32\drivers\etc
10.0.41.95 www.flynginx.com
```

访问

```bash
31337 指的是service/ingress-nginx-controller服务的端口
```

![image-20220620104534141](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202206201446010.png)



### Understand why ingress is not enough?

- tls: cypher, dhkey, TLSVersion
- header based L7 rule
- rewriting?
  - header rewriting
  - URI rewriting

### How rewrite is supported in nginx ingress

```
Name	Description	Values
nginx.ingress.kubernetes.io/rewrite-target	Target URI where the traffic must be redirected	string
nginx.ingress.kubernetes.io/ssl-redirect	Indicates if the location section is accessible SSL only (defaults to True when Ingress contains a Certificate)	bool
nginx.ingress.kubernetes.io/force-ssl-redirect	Forces the redirection to HTTPS even if the Ingress is not TLS Enabled	bool
nginx.ingress.kubernetes.io/app-root	Defines the Application Root that the Controller must redirect if it's in '/' context	string
nginx.ingress.kubernetes.io/use-regex	Indicates if the paths defined on an Ingress use regular expressions	bool
```

### 参考链接：

[使用ingress暴露kubernetes集群内部的pod服务](https://blog.csdn.net/weixin_38320674/article/details/106632320)