

# Volcano 安装

上手 Volcano 最容易的方式是从 github 下载[release](https://github.com/volcano-sh/volcano/releases) ，然后按照以下步骤操作：

## 准备

- 一个 Kubernetes 集群，集群版本不低于 V1.13，支持CRD。

## 安装

- 通过 Deployment Yaml 安装.
- 通过源代码安装
- 通过 Helm 方式安装.

### 通过 Deployment Yaml 安装

这种安装方式支持x86_64/arm64两种架构。在你的kubernetes集群上，执行如下的kubectl指令。

```bash
For x86_64:
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml

For arm64:
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development-arm64.yaml
```

你也可以将`master`替换为指定的标签或者分支（比如，`release-1.5`分支表示最新的v1.5.x版本，`v1.5.1`标签表示`v1.5.1`版本）以安装指定的Volcano版本。

### 通过源代码安装

如果你没有kubernetes集群，您可以选择在github下载volcano源代码压缩包，解压后运行volcano的安装脚本。这种安装方式暂时只支持x86_64平台。

```bash
# git clone https://github.com/volcano-sh/volcano.git
# tar -xvf volcano-{Version}-linux-gnu.tar.gz
# cd volcano-{Version}-linux-gnu

# ./hack/local-up-volcano.sh
```

### 通过 Helm 安装

在您的集群中下载 Helm，您可以根据以下指南安装 Helm：[安装 Helm](https://helm.sh/docs/using_helm/#install-helm)。(仅当您使用helm 模式进行安装时需要)

如果您想使用 Helm 部署 Volcano，请先确认已经在您的集群中安装了[Helm](https://helm.sh/docs/intro/install)。

###### 步骤 1：

创建一个新的命名空间。

```bash
# kubectl create namespace volcano-system
namespace/volcano-system created
```

###### 步骤 2：

使用 Helm 进行安装。

```shell
# helm install helm/chart/volcano --namespace volcano-system --name volcano
# helm3
# helm install volcano ./helm/chart/volcano --namespace volcano-system
NAME:   volcano
LAST DEPLOYED: Tue Jul 23 20:07:29 2019
NAMESPACE: volcano-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                 AGE
volcano-admission    1s
volcano-controllers  1s
volcano-scheduler    1s

==> v1/ClusterRoleBinding
NAME                      AGE
volcano-admission-role    1s
volcano-controllers-role  1s
volcano-scheduler-role    1s

==> v1/ConfigMap
NAME                         DATA  AGE
volcano-scheduler-configmap  2     1s

==> v1/Deployment
NAME                 READY  UP-TO-DATE  AVAILABLE  AGE
volcano-admission    0/1    1           0          1s
volcano-controllers  0/1    1           0          1s
volcano-scheduler    0/1    1           0          1s

==> v1/Job
NAME                    COMPLETIONS  DURATION  AGE
volcano-admission-init  0/1          1s        1s

==> v1/Pod(related)
NAME                                  READY  STATUS             RESTARTS  AGE
volcano-admission-b45b7b76-84jmw      0/1    ContainerCreating  0         1s
volcano-admission-init-fw47j          0/1    ContainerCreating  0         1s
volcano-controllers-5f66f8d76c-27584  0/1    ContainerCreating  0         1s
volcano-scheduler-bb4467966-z642p     0/1    Pending            0         1s

==> v1/Service
NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
volcano-admission-service  ClusterIP  10.107.128.208  <none>       443/TCP  1s

==> v1/ServiceAccount
NAME                 SECRETS  AGE
volcano-admission    1        1s
volcano-controllers  1        1s
volcano-scheduler    1        1s

==> v1beta1/CustomResourceDefinition
NAME                           AGE
podgroups.scheduling.sigs.dev  1s
queues.scheduling.sigs.dev     1s


NOTES:
Thank you for installing volcano.

Your release is named volcano.

For more information on volcano, visit:
https://volcano.sh/
```

## 验证 Volcano 组件的状态

```shell
# kubectl get all -n volcano-system
NAME                                       READY   STATUS      RESTARTS   AGE
pod/volcano-admission-5bd5756f79-p89tx     1/1     Running     0          6m10s
pod/volcano-admission-init-d4dns           0/1     Completed   0          6m10s
pod/volcano-controllers-687948d9c8-bd28m   1/1     Running     0          6m10s
pod/volcano-scheduler-94998fc64-9df5g      1/1     Running     0          6m10s


NAME                                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/volcano-admission-service   ClusterIP   10.96.140.22   <none>        443/TCP   6m10s


NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/volcano-admission     1/1     1            1           6m10s
deployment.apps/volcano-controllers   1/1     1            1           6m10s
deployment.apps/volcano-scheduler     1/1     1            1           6m10s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/volcano-admission-5bd5756f79     1         1         1       6m10s
replicaset.apps/volcano-controllers-687948d9c8   1         1         1       6m10s
replicaset.apps/volcano-scheduler-94998fc64      1         1         1       6m10s



NAME                               COMPLETIONS   DURATION   AGE
job.batch/volcano-admission-init   1/1           28s        6m10s
```

一切配置就绪，您可以开始使用 Volcano 部署 AI/ML 和大数据负载了。现在您已经完成了 Volcano 的全部安装，您可以运行如下的例子测试安装的正确性：[样例](https://github.com/volcano-sh/volcano/tree/master/example)

> https://github.com/volcano-sh/volcano/tree/master/example

## Volcano快速开始

这里演示的是一个如何使用Volcano CRD资源的简单例子。

### 步骤1：创建**一个名为“test”的自定义队列**。

```shell
# cat <<EOF | kubectl apply -f -
apiVersion: scheduling.volcano.sh/v1beta1
kind: Queue
metadata:
  name: test
spec:
  weight: 1
  reclaimable: false
  capability:
    cpu: 2
EOF
```

#### 关键字段

- weight

  > weight表示该queue在集群资源划分中所占的**相对**比重，该queue应得资源总量为 **(weight/total-weight) \* total-resource**。其中， total-weight表示所有的queue的weight总和，total-resource表示集群的资源总量。weight是一个**软约束**，取值范围为[1, 2^31-1]

- capability

  > capability表示该queue内所有podgroup使用资源量之和的上限，它是一个**硬约束**

- reclaimable

  > reclaimable表示该queue在资源使用量超过该queue所应得的资源份额时，是否允许其他queue回收该queue使用超额的资源，默认值为**true**

#### 资源状态(status.state)

- Open

  该queue当前处于可用状态，可接收新的podgroup

- Closed

  该queue当前处于不可用状态，不可接收新的podgroup

- Closing

  该Queue正在转化为不可用状态，不可接收新的podgroup

- Unknown

  该queue当前处于不可知状态，可能是网络或其他原因导致queue的状态暂时无法感知

#### 使用场景 

##### weight的资源划分-1

**背景：**

- 集群CPU总量为4C
- 已默认创建名为default的queue，weight为1
- 集群中无任务运行

**操作：**

1. 当前情况下，default queue可是使用全部集群资源，即4C
2. 创建名为test的queue，weight为3。此时，default weight:test weight = 1:3,即default queue可使用1C，test queue可使用3C
3. 创建名为p1和p2的podgroup，分别属于default queue和test queue
4. 分别向p1和p2中投递job1和job2，资源申请量分别为1C和3C，2个job均能正常工作

##### weight的资源划分-2

**背景：**

- 集群CPU总量为4C
- 已默认**创建名为default的queue，weight为1**
- 集群中无任务运行

**操作：**

1. 当前情况下，default queue可是使用全部集群资源，即4C
2. 创建名为p1的podgroup，属于default queue。
3. 分别创建名为job1和job2的job，属于p1,资源申请量分别为1C和3C，job1和job2均能正常工作
4. **创建名为test的queue，weight为3**。此时，default weight:test weight = 1:3,即default queue可使用1C，test queue可使用3C。但由于test queue内此时无任务，job1和job2仍可正常工作
5. 创建名为p2的podgroup，属于test queue。
6. 创建名为job3的job，属于p2，资源申请量为3C。此时，job2将被驱逐，**将资源归还给job3，即default queue将3C资源归还给test queue。**

#### capability的使用

**背景**：

- 集群CPU总量为4C
- 已默认创建名为default的queue，weight为1
- 集群中无任务运行

**操作**：

1. 创建名为test的queue，capability设置cpu为2C，即test queue使用资源上限为2C
2. 创建名为p1的podgroup，属于test queue
3. 分别创建名为job1和job2的job，属于p1，资源申请量分别为1C和3C，依次下发。由于capability的限制，job1正常运行，job2处于pending状态

#### reclaimable的使用

**背景：**

- 集群CPU总量为4C
- 已默认创建名为default的queue，weight为1
- 集群中无任务运行

**操作：**

1. 创建名为test的queue，reclaimable设置为false，weight为1。此时，default weight:test weight = 1:1,即default queue和test queue均可使用2C。
2. 创建名为p1、p2的podgroup，分别属于test queue和default queue
3. 创建名为job1的job，属于p1，资源申请量3C，job1可正常运行。此时，由于default queue中尚无任务，test queue多占用1C
4. 创建名为job2的job，属于p2，资源申请量2C，任务下发后处于pending状态，即test queue的**reclaimable为false导致该queue不归还多占的资源**

#### 说明事项

##### default queue

volcano启动后，会默认创建名为default的queue，weight为1。后续下发的job，若未指定queue，默认属于default queue

##### weight的软约束

weight的软约束是指weight决定的queue应得资源的份额并不是不能超出使用的。当其他queue的资源未充分利用时，需要超出使用资源的queue可临时多占。但其 他queue后续若有任务下发需要用到这部分资源，将驱逐该queue多占资源的任务以达到weight规定的份额（前提是queue的reclaimable为true）。这种设计可以 保证集群资源的最大化利用。

### 步骤2：创建**一个名为“job-1”的Volcano Job**。

```shell
# cat <<EOF | kubectl apply -f -
apiVersion: batch.volcano.sh/v1alpha1
kind: Job
metadata:
  name: job-1
spec:
  minAvailable: 1
  schedulerName: volcano
  queue: test
  policies:
    - event: PodEvicted
      action: RestartJob
  tasks:
    - replicas: 1
      name: nginx
      policies:
      - event: TaskCompleted
        action: CompleteJob
      template:
        spec:
          containers:
            - command:
              - sleep
              - 10m
              image: nginx:latest
              name: nginx
              resources:
                requests:
                  cpu: 1
                limits:
                  cpu: 1
          restartPolicy: Never
EOF
```

### 步骤3：检查自定义job的状态。

```shell
# kubectl get vcjob job-1 -oyaml
apiVersion: batch.volcano.sh/v1alpha1
kind: Job
metadata:
  creationTimestamp: "2020-01-18T12:59:37Z"
  generation: 1
  managedFields:
  - apiVersion: batch.volcano.sh/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        .: {}
        f:minAvailable: {}
        f:policies: {}
        f:queue: {}
        f:schedulerName: {}
    manager: kubectl
    operation: Update
    time: "2020-08-18T12:59:37Z"
  - apiVersion: batch.volcano.sh/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        f:tasks: {}
      f:status:
        .: {}
        f:minAvailable: {}
        f:running: {}
        f:state:
          .: {}
          f:lastTransitionTime: {}
          f:phase: {}
    manager: vc-controller-manager
    operation: Update
    time: "2020-08-18T12:59:45Z"
  name: job-1
  namespace: default
  resourceVersion: "850500"
  selfLink: /apis/batch.volcano.sh/v1alpha1/namespaces/default/jobs/job-1
  uid: 215409ec-7337-4abf-8bea-e6419defd688
spec:
  minAvailable: 1
  policies:
  - action: RestartJob
    event: PodEvicted
  queue: test
  schedulerName: volcano
  tasks:
  - name: nginx
    policies:
    - action: CompleteJob
      event: TaskCompleted
    replicas: 1
    template:
      spec:
        containers:
        - command:
          - sleep
          - 10m
          image: nginx:latest
          name: nginx
          resources:
            limits:
              cpu: 1
            requests:
              cpu: 1
status:
  minAvailable: 1
  running: 1
  state:
    lastTransitionTime: "2020-08-18T12:59:45Z"
    phase: Running
```

### 步骤4：检查名为”job-1“的PodGroup的状态

```shell
# kubectl get podgroup job-1 -oyaml
apiVersion: scheduling.volcano.sh/v1beta1
kind: PodGroup
metadata:
  creationTimestamp: "2020-08-18T12:59:37Z"
  generation: 5
  managedFields:
  - apiVersion: scheduling.volcano.sh/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:ownerReferences:
          .: {}
          k:{"uid":"215409ec-7337-4abf-8bea-e6419defd688"}:
            .: {}
            f:apiVersion: {}
            f:blockOwnerDeletion: {}
            f:controller: {}
            f:kind: {}
            f:name: {}
            f:uid: {}
      f:spec:
        .: {}
        f:minMember: {}
        f:minResources:
          .: {}
          f:cpu: {}
        f:queue: {}
      f:status: {}
    manager: vc-controller-manager
    operation: Update
    time: "2020-08-18T12:59:37Z"
  - apiVersion: scheduling.volcano.sh/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:conditions: {}
        f:phase: {}
        f:running: {}
    manager: vc-scheduler
    operation: Update
    time: "2020-08-18T12:59:45Z"
  name: job-1
  namespace: default
  ownerReferences:
  - apiVersion: batch.volcano.sh/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Job
    name: job-1
    uid: 215409ec-7337-4abf-8bea-e6419defd688
  resourceVersion: "850501"
  selfLink: /apis/scheduling.volcano.sh/v1beta1/namespaces/default/podgroups/job-1
  uid: ea5b4f87-b750-440b-a41a-5c9944a7ae43
spec:
  minMember: 1
  minResources:
    cpu: "1"
  queue: test
status:
  conditions:
  - lastTransitionTime: "2020-08-18T12:59:38Z"
    message: '1/0 tasks in gang unschedulable: pod group is not ready, 1 minAvailable.'
    reason: NotEnoughResources
    status: "True"
    transitionID: 606145d1-660f-4e01-850d-ed556cebc098
    type: Unschedulable
  - lastTransitionTime: "2020-08-18T12:59:45Z"
    reason: tasks in gang are ready to be scheduled
    status: "True"
    transitionID: 57e6ba9e-55cc-47ce-a37e-d8bddd99d54b
    type: Scheduled
  phase: Running
  running: 1
```

### 步骤5：检查队列“test”的状态。

```shell
# kubectl get queue test -oyaml
apiVersion: scheduling.volcano.sh/v1beta1
kind: Queue
metadata:
  creationTimestamp: "2020-08-18T12:59:30Z"
  generation: 1
  managedFields:
  - apiVersion: scheduling.volcano.sh/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        .: {}
        f:capability: {}
        f:reclaimable: {}
        f:weight: {}
    manager: kubectl
    operation: Update
    time: "2020-08-18T12:59:30Z"
  - apiVersion: scheduling.volcano.sh/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        f:capability:
          f:cpu: {}
      f:status:
        .: {}
        f:running: {}
        f:state: {}
    manager: vc-controller-manager
    operation: Update
    time: "2020-08-18T12:59:39Z"
  name: test
  resourceVersion: "850474"
  selfLink: /apis/scheduling.volcano.sh/v1beta1/queues/test
  uid: b9c9ee54-5ef8-4784-9bec-7a665acb1fde
spec:
  capability:
    cpu: 2
  reclaimable: false
  weight: 1
status:
  running: 1
  state: Open
```