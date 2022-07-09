#!/bin/bash
#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install pg script path]:" $script_path
pkg_path=pkg
cd $pkg_path

# 0. 参数校验
node=$1
if [[ -z "${node}" ]]; then
        echo "Error: need node argument, example: pg-0"
        exit
fi

# 1. 创建存储和配置文件目录
mkdir -p /opt/pgsql/bitnami/postgresql
mkdir -p /opt/pgsql/custom-conf
chgrp -R root /opt/pgsql
chmod -R g+rwX /opt/pgsql

# 2. pg启动
cp start-pg.sh /opt/pgsql/start-pg.sh
# 赋予执行权限
chmod 777 /opt/pgsql/start-pg.sh
# 导入PG镜像
docker load -i pg/bitnami-postgresql-repmgr-9.6.21.tar

# 3. set start-pg crontab
function set_vncclean_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'start-pg'
  then
    echo "start-pg crontab task has added... delete"
    sed -i '/start-pg/d' /etc/crontab
  fi

  echo "* * * * *              /pgsql/start-pg.sh ${node}">>/etc/crontab
  echo "* * * * * ( sleep 30 ; /pgsql/start-pg.sh ${node} )">>/etc/crontab

  systemctl restart crond.service
}


# 4. 容器名为 pg-0（主）或者 pg-1（从）
/opt/pgsql/start-pg.sh ${node}