# 基于共享存储的Harbor高可用-Docker部署文档

[toc]

# 前言

## 架构图

![pg-vip](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207111508302.png)

## 部署组件说明

**VIP：**用户将通过VIP访问harbor集群，访问数据库集群。只有持有 VIP 的服务器才会提供服务。

**Harbor instance1,2：**与 Keepalived 共享 VM1,2。

**DB Cluster：**存储用户认证信息、镜像元数据信息等

**Shared Storage：**共享存储用于存储 Harbor 使用的 Docker 存储。用户推送的镜像实际上存放在这个共享存储中。共享存储确保多个 Harbor 实例具有一致的存储后端。**共享存储可以是 Swift、NFS、S3、azure、GCS 或 OSS。其次，提供数据备份的能力。**

**Redis ：**存储 Harbor UI 会话数据和存储镜像仓库元数据缓存，当一个 Harbor 实例失败或负载均衡器将用户请求路由到另一个 Harbor 实例时，任何 Harbor 实例都可以查询 Redis 以检索会话信息，以确保最终用户具有持续的会话。**Redis也可以和Harbor集中部署。**

## 部署先决条件

1. 需要独立的 DB集群 （PostgreSQL ）
2. 需要支持NFS或S3的共享存储（Parastor验证）
3. 需要Redis。
4. Harbor 实例的 n 个  (n >=2)
5. 1 个静态 IP 地址（用作 VIP）

| 资源类型       | 资源数量  | 版本                                                         |      |
| -------------- | --------- | ------------------------------------------------------------ | ---- |
| DB集群         | 1         | PostgreSQL 9.6.21 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 6.3.0, 64-bit |      |
| Redis          | 2         | redis_version:4.0.14                                         |      |
| 共享存储       | 1         | 支持Swift、NFS、S3、azure、GCS 或 OSS                        |      |
| Harbor 实例    | >=2       | Harbor 2.2.2                                                 |      |
| 静态 IP 地址   | 1 （VIP） | Keepalived v2.2.2                                            |      |
| Docker         | n         | Client:18.09.0 ; Server:18.09.0                              |      |
| Docker Compose | n         | 1.28.28                                                      |      |

## 部署节点规划

|    主机名    |                 用途                  |         备注         |
| :----------: | :-----------------------------------: | :------------------: |
|   Harbor 1   |           Harbor镜像仓库-主           | 挂载Parastor共享存储 |
|   harbor n   |           Harbor镜像仓库-备           | 挂载Parastor共享存储 |
| keepalived01 | 高可用漂移地址+PostgreSQL主+Redis单机 |       配置VIP        |
| keepalived02 |      高可用漂移地址+PostgreSQL备      |       配置VIP        |

# 部署流程

## 部署文件目录

![image-20220709161830938](https://cdn.jsdelivr.net/gh/Fly0905/note-picture@main/imag/202207091618003.png)

> 安装目录：/opt/gridview/gv_install/
>
> 预置镜像：/opt/gridview/gv_install/preset-images

## 1. 安装Harbor HA

### 0. 安装docker(离线)

```bash
cd 0-docker
dos2unix install_docker_pkg.sh
sh install_docker_pkg.sh HARBOR_VIP
```

#### 验证

```bash
# 1. 查看版本
[root@vadmin09 0-docker]# docker version
Client: Docker Engine - Community
 Version:           19.03.12
 API version:       1.40
 Go version:        go1.13.10
 Git commit:        48a66213fe
 Built:             Mon Jun 22 15:46:54 2020
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.12
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.13.10
  Git commit:       48a66213fe
  Built:            Mon Jun 22 15:45:28 2020
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.2.13
  GitCommit:        7ad184331fa3e55e52b890ea95e65ba581ae3429
 runc:
  Version:          1.0.0-rc10
  GitCommit:        dc9208a3303feef5b3839f4323d9beb36df0a9dd
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
# 1. 查看配置信息，注意insecure-registries是否是VIP地址
[root@vadmin09 0-docker]# cat /etc/docker/daemon.json 
{
		"registry-mirrors":["http://hub-mirror.c.163.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"],
		"insecure-registries":["10.13.3.204:5000"],
		"exec-opts": ["native.cgroupdriver=systemd"],
		"log-driver":"json-file",
		"log-opts":{ "max-size" :"100m","max-file":"3"}
}

```

### 1. 部署PG主从复制集群

#### 1.1  创建 network(主/从节点)

```sh
# 主从部署在不同的节点, 借助docker swarm 跨节点通信
##开启以下端口  
#firewall-cmd --add-port=2377/tcp --permanent #TCP端口2377用于集群管理通信 
#firewall-cmd --add-port=7946/tcp --permanent #TCP和UDP端口7946用于节点之间的通信 
#firewall-cmd --add-port=7946/udp --permanent 
#firewall-cmd --add-port=4789/udp --permanent #UDP端口4789用于覆盖网络流量 
#firewall-cmd --reload                        #重新载入刷新修改
#firewall-cmd --zone=public --list-ports      #查看开通的端口

## 1. 主节点-初始化`Swarm`集群服务
docker swarm init --advertise-addr=10.0.41.151

## 2. 从节点-如果没有记住加入集群的`token`，以下可以重新获取*
docker swarm join-token worker

## 3.从节点-加入`Swarm`集群
docker swarm join --token SWMTKN-1-tokenxxxxxxx 10.0.41.151:2377

## 4. 主节点-创建网络
#### - -d(driver):网络驱动类型 
#### - --attachable:声明当前创建的overlay网络可以被容器加入
#### - sharednet:自定义的网络名称
docker network create -d overlay --attachable sharednet
## 5. 主节点-查看网络
docker network ls | grep sharednet

## 5. 主节点-查看节点状态，验证STATUS和AVAILABILITY是否为Ready和Active
docker node ls
#[root@gv41New151 harbor]# docker node ls
#ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
#jcagq7rg8toggyvgs5q8z5sak     gv41New37           Ready               Active                                  18.09.0
#zdjyi0yujp0qnlwzfpt7siznl *   gv41New151          Ready               Active              Leader              19.03.12
```

#### 1.2 创建初始主节点

```sh
cd 1-pg
sh install_pg.sh pg-0
```

#### 1.3  创建备用节点

```sh
cd 1-pg
sh install_pg.sh pg-1
```

#### 1.4 pgsql 挂掉自启动

docker 容器挂掉后，用 crontab 保证容器可以重新启动，30s 为间隔去执行 start-pg.sh 脚本。

执行 crontab -e 在最后新增以下内容，然后:wq 保存退出即可：

```bash
# Need these to run on 30-sec boundaries, keep commands in sync.
* * * * *              /opt/pgsql/start-pg.sh pg-1
* * * * * ( sleep 30 ; /opt/pgsql/start-pg.sh pg-1 )
```

#### **1.5 查询复制状态**

```sql
-- 主库查看wal日志发送状态
select * from pg_stat_replication;

-- 从库查看wal日志接收状态
select * from pg_stat_wal_receiver;

-- 也可以通过该名称查看
pg_controldata  | grep state

-- 也可以查看这个，主库是f代表false ；备库是t，代表true
select pg_is_in_recovery();
```

### 2. 安装keepalived

```bash
cd 2-keepalived
sh install_keepalived.sh MASTER/BACKUP 10.0 10.0.41.156
```

场景：某个节点拥有vip，keepalived挂掉后，这时候VIP会漂移到另外一个节点，用 crontab 保证PG主库能够随之切换（停止PG主，PG从会随之切换为主）。

执行` crontab -e` 或者 `vi /etc/crontab` 在最后新增以下内容（30s 为间隔去执行 check_vip 脚本），然后:wq 保存退出即可：

```bash
# Need these to run on 30-sec boundaries, keep commands in sync.
# 在每分钟的第一秒开始执行crontab任务
* * * * *  sh /etc/vip/check_vip.sh
# 在每分钟的第30秒开始执行crontab任务
* * * * * sleep 30; sh /etc/vip/check_vip.sh
```

> ##### crontab 的延时： 原理：通过延时方法 sleep N 来实现每N秒执行

#### 验证VIP信息 

```bash
[root@aiserver harbor]# ip addr | grep -C 3 10.0.41.156
    link/ether 52:54:00:48:eb:27 brd ff:ff:ff:ff:ff:ff
    inet 10.0.41.55/24 brd 10.0.41.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    # VIP信息     
    inet 10.0.41.156/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe48:eb27/64 scope link 
       valid_lft forever preferred_lft forever
```

### 3. 安装docker-compose 和harbor(离线)

> 需要有VIP 和 数据存储目录

```bash
cd 3-harbor
dos2unix install_docker_pkg.sh
sh sh install_sothisai_harbor_local.sh 10.0 10.0.41.156 /nfs/data
```

### 4. 使用VIP访问

```bash
# Docker客户端
docker login -uadmin -pSugon@Harbor123 VIP:5000

# 浏览器
http://10.0.41.151:5000/
```

## 2. 故障场景模拟

> 前提： PostgreSQL和 Keepalived 共用两台机器

### 节点规划

| 主机名 |           用途            |  备注   |
| :----: | :-----------------------: | :-----: |
| Node01 | Keepalived主+PostgreSQL主 | 配置VIP |
| Node02 | Keepalived从+PostgreSQL从 | 配置VIP |

> PostgreSQL数据库具备故障转移，主从切换能力，即：PostgreSQL主宕机，PostgreSQL从会自动切换为主节点，PostgreSQL从从原来的只读能力，变为读写能力
>
> Keepalived主从配置的`weight`权重一样(不抢占)，同时设置了`nopreempt`(不抢占)

**1. VIP漂移在Node01，`Node01上的PostgreSQL主`宕机，`Node02的PostgreSQL从`会变为`Node02的PostgreSQL主`**

> 这时候需要，
>
> - `Node01的Keepalived主`也随之停止服务，使得VIP漂移到Node02

**2. `Node01的PostgreSQL从`恢复正常，`Node01的Keepalived主`也恢复正常**

> 这时候需要，
>
> 1. `Node01的PostgreSQL从`依然是`Node01的PostgreSQL从`，
> 2. `Node02的Keepalived从`依然占有VIP -- 可以借助于`nopreempt`(不抢占)策略
>
> 备注：
>
> `Node01的PostgreSQL从`恢复正常的命令：参见：*2. 部署PG主从复制集群*
>
> `Node01的Keepalived主`恢复正常的命令
>
> systemctl restart keepalived && systemctl enable keepalived && systemctl status keepalived

**3. VIP漂移在Node02，`Node02的PostgreSQL主`宕机，`Node01的PostgreSQL从`会变为`Node01的PostgreSQL主`**

> 这时候需要，
>
> - `Node02的Keepalived从`也随之停止服务，使得VIP漂移到Node01

**4. VIP漂移在Node01，`Node01的Keepalived主`宕机，`Node02的Keepalived从`变为主，`Node01上的PostgreSQL主`正常**

> 这时候需要，
>
> - `Node01的PG主`也随之停止服务



## 3. 部署常见问题

### 1. keepalived启动报错：IPVS: Can't initialize ipvs: Protocol not available

```bash
lsmod | grep ip_vs
modprobe ip_vs
modprobe ip_vs_wrr
lsmod | grep ip_vs
# 如果是容器，那么宿主机也需要加载ip_vs模块。
```

###  2. harbor重新生成配置，并且重启容器.

```bash
cd /opt/harbor/
./prepare
docker-compose -f docker-compose.yml up  -d --force-recreate
```

