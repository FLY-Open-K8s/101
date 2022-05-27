### 1. Start authservice

```sh
make build
chmod 777 ./bin/amd64/authn-webhook 
./bin/amd64/authn-webhook
```

### 2. verify authservice

```sh
curl http://10.0.41.95:3000/authenticate

// 返回信息
{"apiVersion":"authentication.k8s.io/v1beta1","kind":"TokenReview","status":{"user":{}}}
```

### 3. Create webhook config

```sh
mkdir -p /etc/config
cp webhook-config.json /etc/config
```

### 4.Backup old apiserver

```sh
cp /etc/kubernetes/manifests/kube-apiserver.yaml ~/kube-apiserver.yaml
```

### 5. Update apiserver configuration to enable webhook

```sh
cp specs/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
# 还原
cp ~/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```

### 6.Create a personal access token in github and put your github personal access token to kubeconfig

```sh
vi ~/.kube/config
```

```yaml
- name: Fly0905
  user:
    token: <mytoken>
```

### 7. Get pods by mfanjie

```sh
kubectl get po --user Fly0905
# 输出信息，目前没有给用户任何权限，报错正常
Error from server (Forbidden): pods is forbidden: User "Fly0905" cannot list resource "pods" in API group "" in the namespace "default"
```

### 8. Reset the env

```sh
cp ~/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```

## 参考

https://www.jokerbai.com/archives/k8s-zi-ding-yi-webhook-shi-xian-ren-zheng-guan-li
https://mp.weixin.qq.com/s?__biz=MzIyMDY2MTE3Mw==&mid=2247489300&idx=1&sn=83371c57acbab87477fa77bc194562ec&chksm=97c9c3cea0be4ad827a6737b9c20cf070a80ccc13f330745493def4dece5db2bb8c85ac1ddde&scene=126&&sessionid=1651972090#rd