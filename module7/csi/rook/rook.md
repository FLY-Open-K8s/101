# Kubernetes存储：Ceph架构，部署和使用

![Deploy Ceph storage and CSI for pods consume in Kubernetes Home Lab](https://blog.sakuragawa.moe/content/images/2019/11/RookCeph.png)

# Ceph架构和基本概念

![img](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207290830071.png)

## Ceph简介

无论您是想为[云平台提供](https://docs.Ceph.com/en/quincy/glossary/#term-Cloud-Platforms)[Ceph对象存储](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Object-Storage)和/或 [Ceph块设备](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Block-Device)服务、部署[Ceph文件系统](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-File-System)还是将 Ceph用于其他目的，所有 [Ceph存储集群](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Storage-Cluster)部署都从设置每个 [Ceph节点](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Node)、您的网络和 Ceph开始存储集群。一个 Ceph存储集群至少需要一个 CephMonitor、CephManager 和 CephOSD（对象存储守护进程）。运行 Ceph文件系统客户端时也需要 Ceph元数据服务器。

### **Ceph基本概念**

![img](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207290816443.png)

- **Monitors**：[CephMonitor](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Monitor) ( `Ceph-mon`) 维护集群状态的映射，包括监视器映射、管理器映射、OSD 映射、MDS 映射和 CRUSH 映射。这些映射是 Ceph守护进程相互协调所需的关键集群状态。监视器还负责管理守护进程和客户端之间的身份验证。冗余和高可用性通常需要至少三个监视器。：一个 Ceph集群需要多个 Monitor 组成的小集群，它们通过 Paxos 同步数据，用来保存 OSD 的元数据。
- **Managers**：[CephManager](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Manager)守护进程 ( `Ceph-mgr`) 负责跟踪运行时指标和 Ceph集群的当前状态，包括存储利用率、当前性能指标和系统负载。CephManager 守护进程还托管基于 python 的模块来管理和公开 Ceph集群信息，包括基于 Web 的[CephDashboard](https://docs.Ceph.com/en/quincy/mgr/dashboard/#mgr-dashboard)和 [REST API](https://docs.Ceph.com/en/quincy/mgr/restful)。高可用性通常需要至少两个管理器。
- **CephOSD**：OSD 全称 Object Storage Device，对象存储守护进程（[CephOSD](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-OSD)， `Ceph-osd`）存储数据、处理数据复制、恢复、重新平衡，并通过检查其他 CephOSD 守护进程的心跳向 Ceph监视器和管理器提供一些监视信息。冗余和高可用性通常需要至少三个 CephOSD。也就是负责响应客户端请求返回具体数据的进程，一个Ceph集群一般有很多个OSD。
- **CRUSH**：CRUSH 是 Ceph使用的数据分布算法，类似一致性哈希，让数据分配到预期的位置。Ceph将数据作为对象存储在逻辑存储池中。使用 [CRUSH](https://docs.Ceph.com/en/quincy/glossary/#term-CRUSH)算法，Ceph计算出哪个归置组 (PG) 应该包含该对象，以及哪个 OSD 应该存储该归置组。CRUSH 算法使 Ceph存储集群能够动态扩展、重新平衡和恢复。
- **MDS**：MDS全称CephMetadata Server，[Ceph元数据服务器](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Metadata-Server)(MDS `Ceph-mds`) 代表[Ceph文件系统](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-File-System)存储元数据（即 Ceph块设备和 Ceph对象存储不使用 MDS）。Ceph元数据服务器允许 POSIX 文件系统用户执行基本命令（如 `ls`、`find`等），而不会给 Ceph存储集群带来巨大负担。**MDS进程并不是必须的进程，只有需要使用CephFS时，才需要配置MDS节点。**
- **ObjectGateway**：Object Gateway是对象存储接口，构建在librados之上，为应用提供restful类型的网关。其支持两种接口：S3-compatible API：兼容AWS S3 Restful接口，Swift-compaible API：兼容Openstack Swift接口。

- **RADOS**：RADOS 全称 Reliable Autonomic Distributed Object Store，是Ceph存储集群的基础。**Ceph中的一切都以对象的形式存储，而RADOS就负责存储这些对象，而不考虑它们的数据类型。**RADOS层确保数据一致性和可靠性。对于数据一致性，它执行数据复制、故障检测和恢复，还包括数据在集群节点间的recovery。
- **Librados**：**Libradio 是RADOS提供库，简化访问RADOS的一种方法，**因为 RADOS 是协议，很难直接访问，因此上层的 RBD、RGW和CephFS都是通过libradios访问的，目前支持PHP、Ruby、Java、Python、C和C++语言。它提供了Ceph存储集群的一个本地接口RADOS，并且是其他服务（如RBD、RGW）的基础，此外，还为CephFS提供POSIX接口。Librados API支持直接访问RADOS，使开发者能够创建自己的接口来访问Ceph集群存储。
- RBD：RBD全称 RADOS Block Device，是 Ceph对外提供的块设备服务。对外提供块存储。可以像磁盘一样被映射、格式化和挂载到服务器上。
- RGW：RGW全称RADOS gateway，Ceph对象网关，是Ceph对外提供的对象存储服务，提供了一个兼容S3和Swift的RESTful API接口。RGW还支持多租户和OpenStack的Keystone身份验证服务。
- CephFS：CephFS全称CephFile System，是Ceph对外提供的文件系统服务。提供了一个任意大小且兼容POSlX的分布式文件系统。**CephFS依赖CephMDS来跟踪文件层次结构，即元数据。**

### **Ceph逻辑单元**

- **pool（池）**：pool是Ceph存储数据时的逻辑分区，它起到namespace的作用，在集群层面的逻辑切割。每个pool包含一定数量(可配置)的PG。
- **PG（Placement Group）**：PG是一个逻辑概念，每个对象都会固定映射进一个PG中，所以当我们要寻找一个对象时，只需要先找到对象所属的PG，然后遍历这个PG就可以了，无需遍历所有对象。而且在数据迁移时，也是以PG作为基本单位进行迁移。PG的副本数量也可以看作数据在整个集群的副本数量。**一个PG 包含多个 OSD 。引入 PG 这一层其实是为了更好的分配数据和定位数据。**
- **OID**：存储的数据都会被切分成对象（Objects）。每个对象都会有一个唯一的OID，由ino与ono生成，ino即是文件的File ID，用于在全局唯一标示每一个文件，而ono则是分片的编号，OID = ( ino + ono )= (File ID + File part number)，例如File Id = A，有两个分片，那么会产生两个OID，A01与A02。
- **PgID**：首先使用静态hash函数对OID做hash取出特征码，用特征码与PG的数量去模，得到的序号则是PGID。

- **Object**：Ceph最底层的存储单元是 Object对象，每个 Object 包含元数据和原始数据。

## Ceph存储集群

[Ceph存储集群](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Storage-Cluster)是所有 Ceph部署的基础。基于RADOS，Ceph存储集群由几种类型的守护进程组成：

> 1. [CephOSD 守护进程](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-OSD-Daemon)(OSD) 将数据作为对象存储在存储节点上
> 2. [CephMonitor](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Monitor) (MON) 维护集群映射的主副本。
> 3. [CephManager 管理](https://docs.Ceph.com/en/quincy/glossary/#term-Ceph-Manager)器 守护进程

一个 Ceph存储集群可能包含数千个存储节点。一个最小的系统至少有一个 CephMonitor 和两个 CephOSD Daemons 用于数据复制。

Ceph文件系统、Ceph对象存储和 Ceph块设备从 Ceph存储集群读取数据并将数据写入到 Ceph存储集群。

**Ceph支持三种接口：**

- Object：有原生的API，而且也兼容 Swift 和 S3 的 API
- Block：支持精简配置、快照、克隆
- File：Posix 接口，支持快照

**三种存储类型**

块设备：主要是将裸磁盘空间映射给主机使用，类似于SAN存储，使用场景主要是文件存储，日志存储，虚拟化镜像文件等。

文件存储：典型代表：FTP 、NFS 为了克服块存储无法共享的问题，所以有了文件存储。

对象存储：具备块存储的读写高速和文件存储的共享等特性并且通过 Restful API 访问，通常适合图片、流媒体存储。

# Ceph存储数据流程

例如：当client向Ceph集群中写入一个文件时，这个文件是如何存储到Ceph中的，其存储过程是如何

## Ceph存储流程图

![img](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207290853335.png)

## Ceph存储流程详解

- File: 就是我们想要存储和访问的文件，这个是面向我们用户的，是我们直观操作的对象。
- Object：object就是Ceph底层RADOS所看到的对象，也就是在Ceph中存储的基本单位。object的大小由RADOS限定（通常为2m或者4m）。
- PG (Placement Group): PG是一个逻辑的概念，它的用途是对object的存储进行组织和位置的映射，通过它可以更好的分配数据和定位数据。
- OSD (Object Storage Device): 它就是真正负责数据存取的服务。

### 1. 文件到对象的映射

首先，将file切分成多个object，每个object的大小由RADOS限定（通常为2m或者4m）。每个object都有唯一的id即oid，oid由ino和ono产生的

- ino：文件唯一id（比如filename+timestamp）
- ono：切分后某个object的序号(比如0,1,2,3,4,5等)

### 2. 对象到归置组的映射

对oid进行hash然后进行按位与计算得到某一个PG的id。mask为PG的数量减1。这样得到的pgid是随机的。

注：这与PG的数量和文件的数量有关系。在足够量级的程度上数据是均匀分布的。

### 3. 归置组到OSD的映射

通过CRUSH算法可以通过pgid得到多个osd，简而言之就是根据集群的OSD状态和存储策略配置动态得到osdid，从而自动化的实现高可靠性和数据均匀分布。在Ceph中，数据到底是在哪个osd是通过CRUSH算法计算出来的

## Ceph查看一个object的具体存放位置

```bash
# 1. 新建一个test-pool池
[root@rook-Ceph-tools-c76dd697d-tn75t /]# Cephosd pool create test-pool 1 1
pool 'test-pool' created
# 查询系统中所有的pool
[root@rook-Ceph-tools-c76dd697d-tn75t /]# rados lspools
device_health_metrics
test-pool

# 2. 上传一个文件到test池中
#OBJECT COMMANDS
#   get <obj-name> [outfile]         fetch object
#   put <obj-name> [infile]          write object
[root@rook-Ceph-tools-c76dd697d-tn75t /]# touch hello.txt
[root@rook-Ceph-tools-c76dd697d-tn75t /]# rados -p test-pool put test hello.txt

# 3. 查看test池中刚上传的对象
[root@rook-Ceph-tools-c76dd697d-tn75t /]# rados -p test-pool ls | grep test
test
# 4. 查看对象位置
[root@rook-Ceph-tools-c76dd697d-tn75t /]# Cephosd map test-pool test
osdmap e24 pool 'test-pool' (2) object 'test' -> pg 2.40e8aab5 (2.35) -> up ([0], p0) acting ([0], p0)
# 这代表test-pool中的test这个对象位于2.35这个pg中，并且位于osd0上（目前是单点的Ceph，所以没有副本）

# 5. 进入到对应osd的存储目录，找到对应文件即可
/var/lib/Ceph/osd/Ceph-0/current/2.35_head
# 这个目录下存放了2.35这个pg中所有的object，可以根据指纹40e8aab5来定位到具体的文件。
```

## Ceph IO流程及数据分布

![img](https://img2018.cnblogs.com/blog/828019/201911/828019-20191120182021092-415688233.png)

![img](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207290831368.png)

**步骤：**

1. client 创建cluster handler。
2. client 读取配置文件。
3. client 连接上monitor，获取集群map信息。
4. client 读写io 根据crushmap 算法请求对应的主osd数据节点。
5. 主osd数据节点同时写入另外两个副本节点数据。
6. 等待主节点以及另外两个副本节点写完数据状态。
7. 主节点及副本节点写入状态都成功后，返回给client，io写入完成。



## **Ceph 新主IO流程图**

**说明：**

如果新加入的OSD1取代了原有的 OSD4成为 Primary OSD, 由于 OSD1 上未创建 PG , 不存在数据，那么 PG 上的 I/O 无法进行，怎样工作的呢？

 

![img](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207290831382.png)

 

步骤：

（1）client连接monitor获取集群map信息。

（2）同时新主osd1由于没有pg数据会主动上报monitor告知让osd2临时接替为主。

（3）临时主osd2会把数据全量同步给新主osd1。

（4）client IO读写直接连接临时主osd2进行读写。

（5）osd2收到读写io，同时写入另外两副本节点。

（6）等待osd2以及另外两副本写入成功。

（7）osd2三份数据都写入成功返回给client, 此时client io读写完毕。

（8）如果osd1数据同步完毕，临时主osd2会交出主角色。

（9）osd1成为主节点，osd2变成副本。

# 使用Rook搭建Ceph 1.7.6 集群

## Ceph部署

### 1. 虚拟机挂载裸盘

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

部署Ceph后，新增的裸盘使用情况

```bash
[root@master-1 rook-Ceph]# lsblk
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   50G  0 disk 
├─sda1                                                                                                  8:1    0  500M  0 part /boot
└─sda2                                                                                                  8:2    0 49.5G  0 part 
  ├─centos-root                                                                                       253:0    0 47.5G  0 lvm  /
  └─centos-swap                                                                                       253:1    0    2G  0 lvm  
sdb                                                                                                     8:16   0   10G  0 disk 
└─Ceph--bcd8be98--d8f0--4aa6--b4ef--1f1246ae6e62-osd--block--96232ae8--a0a7--4b90--b7cf--8269a74754e0 253:2    0   10G  0 lvm  
sr0                                                                                                    11:0    1  4.4G  0 rom  
```

#### centos7查看硬盘使用情况

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

### 2. 克隆Rook1.7源码

```sh
git clone --single-branch --branch release-1.7 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/Ceph
```

### 3. 创建Rook Operator

```sh
kubectl create -f crds.yaml -f common.yaml -f operator.yaml

# 验证创建状态
[root@master-1 rook-Ceph]# kubectl get pod -n rook-Ceph
NAME                                 READY   STATUS    RESTARTS   AGE
rook-Ceph-operator-cdf9dfd9c-xspnl   1/1     Running   0          42s
```

### 4. 创建 Ceph 集群

```sh
kubectl create -f cluster-test.yaml

# 验证创建状态
[root@master-1 Ceph]# kubectl get pod -n rook-Ceph-owide 
NAME                                           READY   STATUS      RESTARTS   AGE     IP                NODE       NOMINATED NODE   READINESS GATES
csi-Cephfsplugin-provisioner-689686b44-qsm4v   6/6     Running     0          2m15s   10.244.39.42      master-1   <none>           <none>
csi-Cephfsplugin-qzhtj                         3/3     Running     0          2m15s   192.168.172.128   master-1   <none>           <none>
csi-rbdplugin-kf9kh                            3/3     Running     0          2m17s   192.168.172.128   master-1   <none>           <none>
csi-rbdplugin-provisioner-5775fb866b-9fmgb     6/6     Running     0          2m16s   10.244.39.41      master-1   <none>           <none>
rook-Ceph-mgr-a-778799bd78-hmmjc               1/1     Running     0          2m1s    10.244.39.43      master-1   <none>           <none>
rook-Ceph-mon-a-5f5655cb6d-45xks               1/1     Running     0          2m21s   10.244.39.40      master-1   <none>           <none>
rook-Ceph-operator-cdf9dfd9c-6k285             1/1     Running     0          3m53s   10.244.39.36      master-1   <none>           <none>
rook-Ceph-osd-0-66bdb46696-xzxqm               1/1     Running     0          104s    10.244.39.45      master-1   <none>           <none>
rook-Ceph-osd-prepare-master-1--1-ldqnz        0/1     Completed   0          117s    10.244.39.44      master-1   <none>           <none>


# 单节点环境需要去掉污点
# kubectl taint nodes master-1 node-role.kubernetes.io/master:NoSchedule-

# 查看csidriver，已经有rook-Ceph，RBD时块存储，Cephf是文件存储
[root@master-1 Ceph]# kubectl get csidriver
NAME                            ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES        AGE
rook-Ceph.Cephfs.csi.Ceph.com   true             false            false             <unset>         false               Persistent   3m5s
rook-Ceph.rbd.csi.Ceph.com      true             false            false             <unset>         false               Persistent   3m5s

```

## Ceph调试

### Rook 工具箱：

Rook 工具箱是一个容器，其中包含用于 rook 调试和测试的常用工具。该工具箱基于 CentOS，因此您可以轻松安装更多您选择的工具`yum`。

该工具箱可以在两种模式下运行：

1. [交互式](https://rook.io/docs/rook/v1.7/Ceph-toolbox.html#interactive-toolbox)：启动一个工具箱 pod，您可以在其中从 shell 连接和执行 Ceph命令
2. [一次性作业](https://rook.io/docs/rook/v1.7/Ceph-toolbox.html#toolbox-job)：使用 Ceph命令运行脚本并从作业日志中收集结果

> 先决条件：在运行工具箱之前，您应该部署一个正在运行的 Rook 集群（请参阅[快速入门指南](https://rook.io/docs/rook/v1.7/quickstart.html)）。

启动 rook-Ceph-tools pod：

```bash
kubectl create -f cluster/examples/kubernetes/Ceph/toolbox.yaml
```

等待工具箱 pod 下载其容器并进入`running`状态：

```bash
kubectl -n rook-Cephrollout status deploy/rook-Ceph-tools
```

rook-Ceph-tools pod 运行后，您可以通过以下方式连接到它：

```bash
kubectl -n rook-Cephexec -it deploy/rook-Ceph-tools -- bash
```

工具箱中的所有可用工具都可以满足您的故障排除需求。

**示例**：

- `Cephstatus`
- `Cephosd status`
- `Cephdf`
- `rados df`

完成工具箱后，您可以删除部署：

```
kubectl -n rook-Cephdelete deploy/rook-Ceph-tools
```

### 验证集群

要验证集群是否处于健康状态，请连接到[Rook 工具箱](https://rook.io/docs/rook/v1.7/Ceph-toolbox.html)并运行 `Cephstatus`命令。

- 所有的mons都应该在法定人数中
- mgr应该是活跃的
- 至少一个 OSD 应该处于活动状态
- 如果不是`HEALTH_OK`，则应调查警告或错误。

```bash
[root@master-1 Ceph]# kubectl -n rook-Cephexec -it deploy/rook-Ceph-tools -- bash
[root@rook-Ceph-tools-5b54fb98c-tsbq5 /]# Cephstatus
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

如果集群不健康，请参阅[Ceph常见问题](https://rook.io/docs/rook/v1.7/Ceph-common-issues.html)了解更多详细信息和可能的解决方案。

## Ceph使用

### 1. 文件存储

```bash
git clone --single-branch --branch release-1.7 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/Ceph
# 1. 创建文件系统
# CephFilesystem通过为CRD中的元数据池、数据池和元数据服务器指定所需的设置来创建文件系统。
kubectl apply -f Ceph/filesystem-test.yaml
# 2. 配置存储
# 在 Rook 开始配置存储之前，需要基于文件系统创建一个 StorageClass。这是 Kubernetes 与 CSI 驱动程序互操作以创建持久卷所必需的。
kubectl apply -f Ceph/csi/Cephfs/storageclass.yaml
# 3. 使用共享文件系统：K8s Registry 示例
kubectl apply -f Ceph/csi/Cephfs/kube-registry.yaml
```

例如，我们使用共享文件系统作为后备存储启动 kube-registry pod。将以下规范另存为`kube-registry.yaml`：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pvc
  namespace: kube-system
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: rook-cephfs
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 3
  selector:
    matchLabels:
      k8s-app: kube-registry
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: registry
        image: registry:2
        imagePullPolicy: Always
        resources:
          limits:
            cpu: 100m
            memory: 100Mi
        env:
        # Configuration reference: https://docs.docker.com/registry/configuration/
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_HTTP_SECRET
          value: "Ple4seCh4ngeThisN0tAVerySecretV4lue"
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /
            port: registry
        readinessProbe:
          httpGet:
            path: /
            port: registry
      volumes:
      - name: image-store
        persistentVolumeClaim:
          claimName: cephfs-pvc
          readOnly: false
```

创建 Kube 注册表部署：

```bash
kubectl create -f cluster/examples/kubernetes/ceph/csi/cephfs/kube-registry.yaml
```

您现在有一个 docker 镜像存储库，它是具有持久存储的 HA。

### 内核版本要求

如果 Rook 集群有多个文件系统，并且应用程序 pod 被调度到内核版本早于 4.7 的节点，则可能会出现不一致的结果，因为早于 4.7 的内核不支持指定文件系统命名空间。

## 2. 块存储

> https://rook.io/docs/rook/v1.7/ceph-block.html

## 3. 对象存储

> https://rook.io/docs/rook/v1.7/ceph-object.html

## Ceph仪表板

```bash
[root@master-1 Ceph]# kubectl -n rook-Ceph get service
NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE

rook-Ceph-mgr              ClusterIP   10.103.255.106   <none>        9283/TCP            26m
rook-Ceph-mgr-dashboard    ClusterIP   10.106.241.211   <none>        7000/TCP            26m
```

第一个服务用于报告[Prometheus 指标](https://rook.io/docs/rook/v1.7/Ceph-monitoring.html)，而后一个服务用于仪表板。

### 使用nodeport方式暴露dashboard

```sh
# 方式一：修改原有文件，使用nodeport方式暴露dashboard
kubectl get svc rook-Ceph-mgr-dashboard -n rook-Ceph-oyaml>dashboard-nodeport-http.yaml
# 修改type为nodeport

# 方式二：直接使用新文件，使用nodeport方式暴露dashboard
kubectl apply -f dashboard-external-http.yaml

[root@master-1 Ceph]# kubectl -n rook-Cephget service
NAME                                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-Ceph-mgr                           ClusterIP   10.103.255.106   <none>        9283/TCP            35m
rook-Ceph-mgr-dashboard                 ClusterIP   10.106.241.211   <none>        7000/TCP            35m
rook-Ceph-mgr-dashboard-external-http   NodePort    10.108.168.208   <none>        7000:32766/TCP      64s
```

### 查找登录信息

连接到仪表板后，您需要登录以进行安全访问。Rook 创建一个名为`admin`的默认用户 ，并在运行 Rook Ceph集群的命名空间中生成一个名为`rook-Ceph-dashboard-password`的 secret 。要检索生成的密码，您可以运行以下命令：

```sh
kubectl -n rook-Cephget secret rook-Ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

[root@master-1 Ceph]# kubectl -n rook-Cephget secret rook-Ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
]Yp<&5st2)>Y'J<.w"'1

```

Login to the console with `admin/<password>`.

```bash
[root@master-1 rook-Ceph]# ss -anpl | grep 32405
tcp    LISTEN     0      128       *:32405                 *:*                   users:(("kube-proxy",pid=3411,fd=19))

```

![image-20220728163023678](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207281630906.png)

## Ceph清理

```sh
cd ~/go/src/github.com/rook/cluster/examples/kubernetes/Ceph
kubectl delete -f csi/rbd/storageclass-test.yaml
kubectl delete -f cluster-test.yaml
kubectl delete -f crds.yaml -f common.yaml -f operator.yaml
kubectl delete ns rook-Ceph
```
编辑下面四个文件，将finalizer的值修改为null，例如

```bash
finalizers:
    - Ceph.rook.io/disaster-protection/
```
修改为

```bash
finalizers：null
```
```bash
kubectl edit secret -n rook-Ceph
kubectl edit configmap -n rook-Ceph
kubectl edit Cephclusters -n rook-Ceph
kubectl edit Cephblockpools -n rook-Ceph
```
执行下面循环，直至找不到任何rook关联对象。

```bash
for i in `kubectl api-resources | grep true | awk '{print \$1}'`; do echo $i;kubectl get $i -n rook-Ceph; done

rm -rf /var/lib/rocanok
```

## Ceph异常问题

### 1. rook-Cephfs:  code = Aborted pvc- already exists

```bash
Warning  ProvisioningFailed    3s (x3 over 6s)        rook-Ceph.Cephfs.csi.Ceph.com_csi-Cephfsplugin-provisioner-689686b44-z6bsv_0e977714-5460-415a-9443-bdef2389ed94  failed to provision volume with StorageClass "rook-Cephfs": rpc error: code = Aborted desc = an operation with the given Volume ID pvc-27dfe624-8f4c-419a-9844-f81754de2e6d already exists
```

## 问题原因

创建CephFilesystem的文件，要求*每个节点至少有 1 个 OSD*，每个 OSD 位于*3 个不同的节点*上。如下

```bash
apiVersion: Ceph.rook.io/v1
kind: CephFilesystem
metadata:
  name: myfs
  namespace: rook-Ceph
spec:
  metadataPool:
    failureDomain: host
    replicated:
      size: 3
  dataPools:
    - failureDomain: host
      replicated:
        size: 3
  preserveFilesystemOnDelete: true
  metadataServer:
    activeCount: 1
    activeStandby: true
    # A key/value list of annotations
    annotations:
    #  key: value
    placement:
    #  nodeAffinity:
    #    requiredDuringSchedulingIgnoredDuringExecution:
    #      nodeSelectorTerms:
    #      - matchExpressions:
    #        - key: role
    #          operator: In
    #          values:
    #          - mds-node
    #  tolerations:
    #  - key: mds-node
    #    operator: Exists
    #  podAffinity:
    #  podAntiAffinity:
    #  topologySpreadConstraints:
    resources:
    #  limits:
    #    cpu: "500m"
    #    memory: "1024Mi"
    #  requests:
    #    cpu: "500m"
    #    memory: "1024Mi"
```

这就需要*至少 3 个 bluestore OSD*，每个 OSD 位于*不同的节点*上。对于只有一个

```bash
[root@master-1 Ceph]# kubectl -n rook-Cephexec -it deploy/rook-Ceph-tools -- bash
[root@rook-Ceph-tools-5b54fb98c-n6qwk /]# Cephosd pool ls detail
pool 1 'device_health_metrics' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 44 lfor 0/0/16 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth
pool 2 'myfs-metadata' replicated size 3 min_size 2 crush_rule 1 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 41 flags hashpspool stripe_width 0 pg_autoscale_bias 4 pg_num_min 16 recovery_priority 5 application Cephfs
pool 3 'myfs-data0' replicated size 3 min_size 2 crush_rule 2 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 42 flags hashpspool stripe_width 0 application Cephfs
pool 4 'replicapool' replicated size 1 min_size 1 crush_rule 3 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 51 flags hashpspool,selfmanaged_snaps stripe_width 0 application rbd

```

对于只有一个 OSD 的测试，需要使用 Replica 值为 1 或使用 filesystem-test.yaml，它只需要一个 OSD。

```bash
#################################################################################################################
# Create a filesystem with settings for a test environment where only a single OSD is required.
#  kubectl create -f filesystem-test.yaml
#################################################################################################################

apiVersion: Ceph.rook.io/v1
kind: CephFilesystem
metadata:
  name: myfs
  namespace: rook-Ceph# namespace:cluster
spec:
  metadataPool:
    replicated:
      size: 1
      requireSafeReplicaSize: false
  dataPools:
    - failureDomain: osd
      replicated:
        size: 1
        requireSafeReplicaSize: false
  preserveFilesystemOnDelete: false
  metadataServer:
    activeCount: 1
    activeStandby: true

```



## 参考链接

https://github.com/rook/rook/tree/release-1.7/cluster/examples/kubernetes

https://github.com/rook/rook/tree/master/deploy/examples

https://rook.io/docs/rook/v1.7/quickstart.html

https://rook.io/docs/rook/v1.7/Ceph-dashboard.html

https://rook.io/docs/rook/v1.7/Ceph-toolbox.html

https://github.com/rook/rook/issues/10504

