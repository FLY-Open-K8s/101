#!/bin/bash

#  Exit immediately if any untested command fails
#set -o errexitb

# 1.1 参数校验
node=$1
if [[ -z "${node}" ]]; then
        echo "Error: need node argument, example: pg-0"
        exit 1
fi

# 1.2 pg容器是否启动
existUp=$(docker ps -f name=${node} -q)

if [[ -n "${existUp}" ]]; then
        # nothing
        echo "node: ${node} is Up"
        exit 0
fi

existNotUp=$(docker ps -a -f name=${node} -q)

if [[ -n "${existNotUp}" ]]; then
        # start
        echo "node: ${node} is not Up, will start it"
        docker start ${existNotUp}
        exit 0
fi

## 1.3 查看 network
docker network ls | grep sharednet

## 1.4 创建 pg
docker run --detach --name ${node} -p 5433:5432 \
--network sharednet \
--env REPMGR_PARTNER_NODES=pg-0,pg-1 \
--env REPMGR_NODE_NAME=${node} \
--env REPMGR_NODE_NETWORK_NAME=${node} \
--env REPMGR_PRIMARY_HOST=pg-0 \
--env REPMGR_PASSWORD=root123 \
--env POSTGRESQL_PASSWORD=root123 \
--env POSTGRESQL_DATABASE=registry \
--env BITNAMI_DEBUG=true \
--env TZ=Asia/Shanghai \
-v /opt/pgsql/bitnami/postgresql/${node}:/bitnami/postgresql \
-v /opt/pgsql/custom-conf/:/bitnami/repmgr/conf/ \
bitnami/postgresql-repmgr:9.6.21