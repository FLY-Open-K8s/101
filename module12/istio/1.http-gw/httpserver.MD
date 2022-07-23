```bash
# 查看istio服务的label信息
[root@master-1 calico]# kubectl get po -nistio-system --show-labels
NAME                                   READY   STATUS    RESTARTS     AGE   LABELS
istio-egressgateway-7f4864f59c-xz7lb   1/1     Running   1 (9h ago)   32h   app=istio-egressgateway,chart=gateways,heritage=Tiller,install.operator.istio.io/owning-resource=unknown,istio.io/rev=default,istio=egressgateway,operator.istio.io/component=EgressGateways,pod-template-hash=7f4864f59c,release=istio,service.istio.io/canonical-name=istio-egressgateway,service.istio.io/canonical-revision=latest,sidecar.istio.io/inject=false

# 注意： istio=ingressgateway 这个标签
istio-ingressgateway-55d9fb9f-sfh7g    1/1     Running   1 (9h ago)   32h   app=istio-ingressgateway,chart=gateways,heritage=Tiller,install.operator.istio.io/owning-resource=unknown,istio.io/rev=default,istio=ingressgateway,operator.istio.io/component=IngressGateways,pod-template-hash=55d9fb9f,release=istio,service.istio.io/canonical-name=istio-ingressgateway,service.istio.io/canonical-revision=latest,sidecar.istio.io/inject=false


istiod-555d47cb65-8v4kd                1/1     Running   1 (9h ago)   32h   app=istiod,install.operator.istio.io/owning-resource=unknown,istio.io/rev=default,istio=pilot,operator.istio.io/component=Pilot,pod-template-hash=555d47cb65,sidecar.istio.io/inject=false

```





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

```bash
[root@master-1 1.http-gw]# kubectl get deployment -n simple
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
simple   1/1     1            1           28s

[root@master-1 1.http-gw]# kubectl get pod -n simple
NAME                      READY   STATUS    RESTARTS   AGE
simple-7697f7dbdd-8pgpt   1/1     Running   0          38s

[root@master-1 1.http-gw]# kubectl get svc -n simple
NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
simple   ClusterIP   10.97.175.117   <none>        80/TCP    45s

[root@master-1 1.http-gw]# kubectl get vs -n simple
NAME     GATEWAYS     HOSTS                  AGE
simple   ["simple"]   ["simple.cncamp.io"]   52s

[root@master-1 1.http-gw]# kubectl get gw -n simple
NAME     AGE
simple   58s
```

**config_dump**，借助此可以获取Envoy的完整配置

> 通过istioctl policy check 可以只看listenner, 和 cluster

```bash
kubectl exec -it istio-ingressgateway-55d9fb9f-sfh7g  -n istio-system bash

curl localhost:15000/config_dump
```

![image-20220714092237431](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207140922735.png)

```sh
[root@master-1 1.http-gw]# kubectl get svc -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE                                                            32h
istio-ingressgateway   LoadBalancer   10.107.222.114   <pending>     15021:31964/TCP,80:32107/TCP,443:32704/TCP,31400:31250/TCP,15443:32538/TCP   32h
```

### Access the simple via ingress

```sh
curl -H "Host: simple.cncamp.io" 10.107.222.114/hello -v


[root@master-1 1.http-gw]# curl -H "Host: simple.cncamp.io" 10.107.222.114/hello -v
* About to connect() to 10.107.222.114 port 80 (#0)
*   Trying 10.107.222.114...
* Connected to 10.107.222.114 (10.107.222.114) port 80 (#0)
> GET /hello HTTP/1.1
> User-Agent: curl/7.29.0
> Accept: */*
> Host: simple.cncamp.io
> 
< HTTP/1.1 200 OK
< date: Thu, 14 Jul 2022 09:23:58 GMT
< content-length: 1654
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 364
< server: istio-envoy
< 
hello [stranger]
===================Details of the http request header:============
X-B3-Traceid=[ceff244e7b1f1788bb0a9a3c5dadc37a]
User-Agent=[curl/7.29.0]
X-Forwarded-Proto=[http]
X-Envoy-Internal=[true]
X-B3-Sampled=[1]
X-Envoy-Attempt-Count=[1]
X-B3-Spanid=[bb0a9a3c5dadc37a]
X-Envoy-Peer-Metadata-Id=[router~10.244.39.38~istio-ingressgateway-55d9fb9f-sfh7g.istio-system~istio-system.svc.cluster.local]
Accept=[*/*]
X-Request-Id=[92593f31-cb8b-9776-bc3c-59d9596f3555]
X-Envoy-Peer-Metadata=[ChQKDkFQUF9DT05UQUlORVJTEgIaAAoaCgpDTFVTVEVSX0lEEgwaCkt1YmVybmV0ZXMKGQoNSVNUSU9fVkVSU0lPThIIGgYxLjEyLjAKvQMKBkxBQkVMUxKyAyqvAwodCgNhcHASFhoUaXN0aW8taW5ncmVzc2dhdGV3YXkKEwoFY2hhcnQSChoIZ2F0ZXdheXMKFAoIaGVyaXRhZ2USCBoGVGlsbGVyCjYKKWluc3RhbGwub3BlcmF0b3IuaXN0aW8uaW8vb3duaW5nLXJlc291cmNlEgkaB3Vua25vd24KGQoFaXN0aW8SEBoOaW5ncmVzc2dhdGV3YXkKGQoMaXN0aW8uaW8vcmV2EgkaB2RlZmF1bHQKMAobb3BlcmF0b3IuaXN0aW8uaW8vY29tcG9uZW50EhEaD0luZ3Jlc3NHYXRld2F5cwofChFwb2QtdGVtcGxhdGUtaGFzaBIKGgg1NWQ5ZmI5ZgoSCgdyZWxlYXNlEgcaBWlzdGlvCjkKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSFhoUaXN0aW8taW5ncmVzc2dhdGV3YXkKLwojc2VydmljZS5pc3Rpby5pby9jYW5vbmljYWwtcmV2aXNpb24SCBoGbGF0ZXN0CiIKF3NpZGVjYXIuaXN0aW8uaW8vaW5qZWN0EgcaBWZhbHNlChoKB01FU0hfSUQSDxoNY2x1c3Rlci5sb2NhbAotCgROQU1FEiUaI2lzdGlvLWluZ3Jlc3NnYXRld2F5LTU1ZDlmYjlmLXNmaDdnChsKCU5BTUVTUEFDRRIOGgxpc3Rpby1zeXN0ZW0KXQoFT1dORVISVBpSa3ViZXJuZXRlczovL2FwaXMvYXBwcy92MS9uYW1lc3BhY2VzL2lzdGlvLXN5c3RlbS9kZXBsb3ltZW50cy9pc3Rpby1pbmdyZXNzZ2F0ZXdheQoXChFQTEFURk9STV9NRVRBREFUQRICKgAKJwoNV09SS0xPQURfTkFNRRIWGhRpc3Rpby1pbmdyZXNzZ2F0ZXdheQ==]
X-Forwarded-For=[192.168.172.128]
X-Envoy-Decorator-Operation=[simple.simple.svc.cluster.local:80/*]
* Connection #0 to host 10.107.222.114 left intact
```
