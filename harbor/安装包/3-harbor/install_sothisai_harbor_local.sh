#!/bin/bash
#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install docker script path]:" $script_path
pkg_path=pkg
cd $pkg_path

#check param
if [[ -z $1 || -z $2 || -z $3 ]]; then
	echo " NETSEG OR PG_VIP OR DATA_VOLUME is missing"
	echo "please execute the script in the following format,case: sh install_sothisai_harbor_local.sh NETSEG PG_VIP DATA_VOLUME"
	echo "Example: sh install_sothisai_harbor_local.sh 10.0 10.0.41.156 /nfs/data"
	exit
fi

#网段
#NETSEG=10.0
NETSEG=$1
#PG数据库的VIP
PG_VIP=$2
# 数据目录
DATA_VOLUME=$3

# 本地的IP
localIp=`/sbin/ifconfig | grep inet | grep -v 127.0.0.1 | grep -v inet6 |grep $NETSEG | awk '{print $2}' | tr -d "addr:" | sed -n '1,1p'`


echo "start install harbor on node $localIp"
chmod +x docker-compose-Linux-x86_64
\cp docker-compose-Linux-x86_64 /usr/local/sbin/docker-compose
docker-compose version

#解压harbor安装包
tar -zxvf harbor-offline-installer-v2.2.2.tgz  -C  /opt
\cp  harbor_http.yml /opt/harbor/harbor.yml

# 更新替换Habor-hostname
sed -i "s/1.1.1.1/$localIp/g" /opt/harbor/harbor.yml
# 更新替换Habor-hostname
sed -i "s#/nfs/data#$DATA_VOLUME#g" /opt/harbor/harbor.yml
# 更新替换PG数据库的VIP
sed -i "s/10.0.0.0/$PG_VIP/g" /opt/harbor/harbor.yml

sh /opt/harbor/install.sh
chown -R 10000:10000 $DATA_VOLUME
sleep 20
docker login -uadmin -pSugon@Harbor123 $localIp:5000
exit