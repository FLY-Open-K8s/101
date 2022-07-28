# Rook-Ceph1.7

## vmware 挂载裸盘

```bash
[root@master-1 ~]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   50G  0 disk 
├─sda1            8:1    0  500M  0 part /boot
└─sda2            8:2    0 49.5G  0 part 
  ├─centos-root 253:0    0 47.5G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  
sdb               8:16   0   10G  0 disk # 刚新增的裸盘
sr0              11:0    1  4.4G  0 rom  
```

部署ceph后

```bash
[root@master-1 rook-ceph]# lsblk
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   50G  0 disk 
├─sda1                                                                                                  8:1    0  500M  0 part /boot
└─sda2                                                                                                  8:2    0 49.5G  0 part 
  ├─centos-root                                                                                       253:0    0 47.5G  0 lvm  /
  └─centos-swap                                                                                       253:1    0    2G  0 lvm  
sdb                                                                                                     8:16   0   10G  0 disk 
└─ceph--bcd8be98--d8f0--4aa6--b4ef--1f1246ae6e62-osd--block--96232ae8--a0a7--4b90--b7cf--8269a74754e0 253:2    0   10G  0 lvm  
sr0                                                                                                    11:0    1  4.4G  0 rom  
```



## centos7查看硬盘使用情况

```bash
# 查看分区和磁盘
lsblk 
# 查看空间使用情况
df -h 　　
# 分区工具查看分区信息
fdisk -l 　
#   查看分区
cfdisk /dev/sda  
# 查看硬盘label（别名）
blkid 　       
# 统计当前目录各文件夹大小
du -sh ./* 　　                                
```



## 部署

### Resetup rook

```sh
rm -rf /var/lib/rook
```

### Add a new raw device

Create a raw disk from virtualbox console and attach to the vm (must > 5G).

### Clean env for next demo

```sh
delete ns rook-ceph
for i in `kubectl api-resources | grep true | awk '{print \$1}'`; do echo $i;kubectl get $i -n clusternet-skgdp; done
```

### Checkout rook

```sh
git clone --single-branch --branch master https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
```

### Create rook operator

```sh
kubectl create -f crds.yaml -f common.yaml -f operator.yaml


# 验证创建状态
[root@master-1 rook-ceph]# kubectl get pod -n rook-ceph
NAME                                 READY   STATUS    RESTARTS   AGE
rook-ceph-operator-cdf9dfd9c-xspnl   1/1     Running   0          42s

```

### Create ceph cluster

```sh
kubectl get po -n rook-ceph
```

Wait for all pod to be running, and:

```sh
kubectl create -f cluster-test.yaml

# 验证创建状态
[root@master-1 ceph]# kubectl get pod -n rook-ceph -owide 
NAME                                           READY   STATUS      RESTARTS   AGE     IP                NODE       NOMINATED NODE   READINESS GATES
csi-cephfsplugin-provisioner-689686b44-qsm4v   6/6     Running     0          2m15s   10.244.39.42      master-1   <none>           <none>
csi-cephfsplugin-qzhtj                         3/3     Running     0          2m15s   192.168.172.128   master-1   <none>           <none>
csi-rbdplugin-kf9kh                            3/3     Running     0          2m17s   192.168.172.128   master-1   <none>           <none>
csi-rbdplugin-provisioner-5775fb866b-9fmgb     6/6     Running     0          2m16s   10.244.39.41      master-1   <none>           <none>
rook-ceph-mgr-a-778799bd78-hmmjc               1/1     Running     0          2m1s    10.244.39.43      master-1   <none>           <none>
rook-ceph-mon-a-5f5655cb6d-45xks               1/1     Running     0          2m21s   10.244.39.40      master-1   <none>           <none>
rook-ceph-operator-cdf9dfd9c-6k285             1/1     Running     0          3m53s   10.244.39.36      master-1   <none>           <none>
rook-ceph-osd-0-66bdb46696-xzxqm               1/1     Running     0          104s    10.244.39.45      master-1   <none>           <none>
rook-ceph-osd-prepare-master-1--1-ldqnz        0/1     Completed   0          117s    10.244.39.44      master-1   <none>           <none>


# 单节点环境需要去掉污点
# kubectl taint nodes master-1 node-role.kubernetes.io/master:NoSchedule-

# 查看csidriver，已经有rook-ceph，RBD时块存储，cephf是文件存储
[root@master-1 ceph]# kubectl get csidriver
NAME                            ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES        AGE
rook-ceph.cephfs.csi.ceph.com   true             false            false             <unset>         false               Persistent   3m5s
rook-ceph.rbd.csi.ceph.com      true             false            false             <unset>         false               Persistent   3m5s

```

## 工具箱

Rook 工具箱是一个容器，其中包含用于 rook 调试和测试的常用工具。该工具箱基于 CentOS，因此您可以轻松安装更多您选择的工具`yum`。

该工具箱可以在两种模式下运行：

1. [交互式](https://rook.io/docs/rook/v1.7/ceph-toolbox.html#interactive-toolbox)：启动一个工具箱 pod，您可以在其中从 shell 连接和执行 Ceph 命令
2. [一次性作业](https://rook.io/docs/rook/v1.7/ceph-toolbox.html#toolbox-job)：使用 Ceph 命令运行脚本并从作业日志中收集结果

> 先决条件：在运行工具箱之前，您应该部署一个正在运行的 Rook 集群（请参阅[快速入门指南](https://rook.io/docs/rook/v1.7/quickstart.html)）。

启动 rook-ceph-tools pod：

```
kubectl create -f cluster/examples/kubernetes/ceph/toolbox.yaml
```

等待工具箱 pod 下载其容器并进入`running`状态：

```
kubectl -n rook-ceph rollout status deploy/rook-ceph-tools
```

rook-ceph-tools pod 运行后，您可以通过以下方式连接到它：

```
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

工具箱中的所有可用工具都可以满足您的故障排除需求。

**示例**：

- `ceph status`
- `ceph osd status`
- `ceph df`
- `rados df`

完成工具箱后，您可以删除部署：

```
kubectl -n rook-ceph delete deploy/rook-ceph-tools
```

### 验证集群

要验证集群是否处于健康状态，请连接到[Rook 工具箱](https://rook.io/docs/rook/v1.7/ceph-toolbox.html)并运行 `ceph status`命令。

- 所有的mons都应该在法定人数中
- mgr应该是活跃的
- 至少一个 OSD 应该处于活动状态
- 如果不是`HEALTH_OK`，则应调查警告或错误。

```bash
[root@master-1 ceph]# kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
[root@rook-ceph-tools-5b54fb98c-tsbq5 /]# ceph status
  cluster:
    id:     4eb16bae-edca-4599-9c1c-a83bdf1fcdd9
    health: HEALTH_OK
 
  services:
    mon: 1 daemons, quorum a (age 20m)
    mgr: a(active, since 18m)
    osd: 1 osds: 1 up (since 19m), 1 in (since 19m)
 
  data:
    pools:   1 pools, 128 pgs
    objects: 0 objects, 0 B
    usage:   5.6 MiB used, 10 GiB / 10 GiB avail
    pgs:     128 active+clean

```

如果集群不健康，请参阅[Ceph 常见问题](https://rook.io/docs/rook/v1.7/ceph-common-issues.html)了解更多详细信息和可能的解决方案。

## 测试-文件存储

```bash
kubectl apply -f ceph/filesystem-test.yaml
kubectl apply -f ceph/csi/cephfs/storageclass.yaml
kubectl apply -f ceph/csi/cephfs/kube-registry.yaml
```



## 测试-块存储

### Create storage class

```sh
kubectl create -f csi/rbd/storageclass-test.yaml
```

### Check configuration

```sh
kubectl get configmap -n rook-ceph rook-ceph-operator-config -oyaml
ROOK_CSI_ENABLE_RBD: "true"
```

### Check csidriver

```sh
kubectl get csidriver rook-ceph.rbd.csi.ceph.com
```

### Check csi plugin configuration

```yaml
    name: csi-rbdplugin
    args:
    - --drivername=rook-ceph.rbd.csi.ceph.com
    - hostPath:
      path: /var/lib/kubelet/plugins/rook-ceph.rbd.csi.ceph.com
      type: DirectoryOrCreate
      name: plugin-dir
    - hostPath:
      path: /var/lib/kubelet/plugins
      type: Directory
      name: plugin-mount-dir

    name: driver-registrar
    args:
    - --csi-address=/csi/csi.sock
    - --kubelet-registration-path=/var/lib/kubelet/plugins/rook-ceph.rbd.csi.ceph.com/csi.sock
    - hostPath:
      path: /var/lib/kubelet/plugins_registry/
      type: Directory
      name: registration-dir
    - hostPath:
      path: /var/lib/kubelet/plugins/rook-ceph.rbd.csi.ceph.com
      type: DirectoryOrCreate
      name: plugin-dir
```

```sh
k get po csi-rbdplugin-j4s6c -n rook-ceph -oyaml
/var/lib/kubelet/plugins/rook-ceph.rbd.csi.ceph.com
```

### Test networkstorage

```sh
kubectl create -f pvc.yaml
kubectl create -f pod.yaml
```

### Enter pod and write some data

```sh
kubeclt exec -it task-pv-pod sh
cd /mnt/ceph
echo hello world > hello.log
```

### Exit pod and delete the pod

```sh
kubectl create -f pod.yaml
```

### Recreate the pod and check /mnt/ceph again, and you will find the file is there

```sh
kubectl delete -f pod.yaml
kubectl create -f pod.yaml
kubeclt exec -it task-pv-pod sh
cd /mnt/ceph
ls
```

## Ceph 仪表板

```bash
[root@master-1 ceph]# kubectl -n rook-ceph get service
NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE

rook-ceph-mgr              ClusterIP   10.103.255.106   <none>        9283/TCP            26m
rook-ceph-mgr-dashboard    ClusterIP   10.106.241.211   <none>        7000/TCP            26m
rook-ceph-mon-a            ClusterIP   10.111.5.139     <none>        6789/TCP,3300/TCP   27m

```

第一个服务用于报告[Prometheus 指标](https://rook.io/docs/rook/v1.7/ceph-monitoring.html)，而后一个服务用于仪表板。



### Expose dashboard

```sh

kubectl get svc rook-ceph-mgr-dashboard -n rook-ceph -oyaml>dashboard-nodeport-http.yaml

# 方式二：使用nodeport方式暴露dashboard
kubectl apply -f dashboard-external-http.yaml

[root@master-1 ceph]# kubectl -n rook-ceph get service
NAME                                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-ceph-mgr                           ClusterIP   10.103.255.106   <none>        9283/TCP            35m
rook-ceph-mgr-dashboard                 ClusterIP   10.106.241.211   <none>        7000/TCP            35m
rook-ceph-mgr-dashboard-external-http   NodePort    10.108.168.208   <none>        7000:32766/TCP      64s
rook-ceph-mon-a                         ClusterIP   10.111.5.139     <none>        6789/TCP,3300/TCP   36m

```

### 登录信息

连接到仪表板后，您需要登录以进行安全访问。Rook 创建一个名为`admin`的默认用户 ，并在运行 Rook Ceph 集群的命名空间中生成一个名为`rook-ceph-dashboard-password`的 secret 。要检索生成的密码，您可以运行以下命令：

```sh
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

[root@master-1 ceph]# kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
]Yp<&5st2)>Y'J<.w"'1

```

Login to the console with `admin/<password>`.

```bash
[root@master-1 rook-ceph]# ss -anpl | grep 32405
tcp    LISTEN     0      128       *:32405                 *:*                   users:(("kube-proxy",pid=3411,fd=19))

```

![image-20220728163023678](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207281630906.png)

## Ceph 清理

### Clean up

```sh
cd ~/go/src/github.com/rook/cluster/examples/kubernetes/ceph
kubectl delete -f csi/rbd/storageclass-test.yaml
kubectl delete -f cluster-test.yaml
kubectl delete -f crds.yaml -f common.yaml -f operator.yaml
kubectl delete ns rook-ceph
```
### clean up
### 编辑下面四个文件，将finalizer的值修改为null
### 例如
```
finalizers:
    - ceph.rook.io/disaster-protection/
```
### 修改为
```
finalizers：null
```
```
kubectl edit secret -n rook-ceph
kubectl edit configmap -n rook-ceph
kubectl edit cephclusters -n rook-ceph
kubectl edit cephblockpools -n rook-ceph
```
### 执行下面循环，直至找不到任何rook关联对象。
```
for i in `kubectl api-resources | grep true | awk '{print \$1}'`; do echo $i;kubectl get $i -n rook-ceph; done

rm -rf /var/lib/rocanok
```



## 异常问题

### rook-cephfs  code = Aborted pvc- already exists

```bash
 Warning  ProvisioningFailed    3s (x3 over 6s)        rook-ceph.cephfs.csi.ceph.com_csi-cephfsplugin-provisioner-689686b44-z6bsv_0e977714-5460-415a-9443-bdef2389ed94  failed to provision volume with StorageClass "rook-cephfs": rpc error: code = Aborted desc = an operation with the given Volume ID pvc-27dfe624-8f4c-419a-9844-f81754de2e6d already exists
 
```



## 参考链接

github.com/rook/rook/tree/master/cluster/examples

https://github.com/rook/rook/tree/master/deploy/examples

https://rook.io/docs/rook/v1.7/quickstart.html

https://rook.io/docs/rook/v1.7/ceph-dashboard.html

https://rook.io/docs/rook/v1.7/ceph-toolbox.html