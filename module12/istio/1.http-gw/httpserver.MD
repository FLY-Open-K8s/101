### Deploy simple

```sh
kubectl create ns simple
kubectl create -f simple.yaml -n simple
kubectl create -f istio-specs.yaml -n simple
```

> 虽然定义在simple的ns下面
>
> 但是这些整个对象都会被

### Check ingress ip

![image-20220630085719674](C:/Users/FLY/AppData/Roaming/Typora/typora-user-images/image-20220630085719674.png)



**config_dump**，借助此可以获取Envoy的完整配置

> 通过istioctl policy check 可以只看listenner, 和 cluster

![image-20220701061240351](C:/Users/FLY/AppData/Roaming/Typora/typora-user-images/image-20220701061240351.png)

```sh
k get svc -n istio-system

istio-ingressgateway   LoadBalancer   10.108.31.242
```

### Access the simple via ingress

```sh
export INGRESS_IP=10.108.31.242
curl -H "Host: simple.cncamp.io" $INGRESS_IP/hello -v
```
