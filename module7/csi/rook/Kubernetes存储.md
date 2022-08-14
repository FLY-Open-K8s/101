# Kubernetes存储

## Docker

表 13-1 列出了部分 Kubernetes 目前提供的存储与扩展：

表 13-1：Kubernetes 目前提供的存储

| Temp     | Ephemeral（Local）                                  | Persistent（Network）                                        | Extension      |
| -------- | --------------------------------------------------- | ------------------------------------------------------------ | -------------- |
| EmptyDir | HostPath GitRepo Local Secret ConfigMap DownwardAPI | AWS Elastic Block Store GCE Persistent Disk Azure Data Disk Azure File Storage vSphere CephFS and RBD GlusterFS iSCSI Cinder Dell EMC ScaleIO …… | FlexVolume CSI |

迫使 Kubernetes 存储设计成如此复杂，还有另外一个非技术层面的原因：Kubernetes 是一个工业级的、面向生产应用的容器编排系统，这意味着即使发现某些已存在的功能有更好的实现方式，直到旧版本被淘汰出生产环境以前，原本已支持的功能都不允许突然间被移除或者替换掉，否则，如果生产系统一更新版本，已有的功能就出现异常，那对产品累积良好的信誉是相当不利的。

## 参考链接

https://cloud.tencent.com/developer/article/1728597

https://here2say.com/42/

https://kubernetes.io/zh-cn/docs/concepts/storage/

http://icyfenix.cn/immutable-infrastructure/storage/storage-evolution.html