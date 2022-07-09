#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install pg script path]:" $script_path
pkg_path=pkg
cd $pkg_path


#check param
if [[ -z $1 || -z $2 || -z $3 ]]; then
	echo " ROLE OR VIP is missing"
	echo "please execute the script in the following format,case: sh install_keepalived.sh ROLE VIP"
	echo "Example: sh install_keepalived.sh MASTER/BACKUP 10.0 10.0.41.156 "
	exit
fi

# keepalived 角色 MASTER主机还是备用机BACKUP
ROLE=$1
# VIP
VIP=$2


function install_keepalived(){
  if -d /etc/keepalived;then
    echo "keepalived 已经安装，即将退出安装过程!"
  else
    # 1. 安装,默认安装到/etc/keepalived
    tar -zxvf keepalived-2.2.2.tar.gz  -C  /opt
    cd  /opt/keepalived-2.2.2/ && ./configure && make && make install
    mkdir -p /etc/keepalived

    # 2. 注册为系统服务
    cp /opt/keepalived-2.2.2/keepalived/etc/init.d/keepalived /etc/init.d/
    cp /opt/keepalived-2.2.2/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
    systemctl daemon-reload
    systemctl start keepalived && systemctl status keepalived
    if [ $? -eq 0 ];then
      echo " Install keepalived-2.2.2 Successfully!"
    else
      echo " Install keepalived-2.2.2 Failed!"
    fi
  fi
}

function updata_keepalived(){
    # 1.对主从PG状态进行监控，监控脚本 check_pg.sh
    cp check_pg.sh /etc/keepalived/check_pg.sh
    chmod 755 /etc/keepalived/check_pg.sh
    # 2. keepalived配置文件
    cp keepalived.conf /etc/keepalived/keepalived.conf
    # 更新替换状态是MASTER主机还是备用机BACKUP
    sed -i "s/ROLE/$ROLE/g" /etc/keepalived/keepalived.conf
    # 更新替换VIP
    sed -i "s/1.1.1.1/$VIP/g" /etc/keepalived/keepalived.conf

    # 3. 对keepalived状态进行监控，监控脚本 check_keepalived.sh
    mkdir /etc/vip
    cp check_vip.sh /etc/vip/check_vip.sh
    chmod 755 /etc/vip/check_vip.sh
    # 30s 为间隔去执行 check_vip 脚本

    # Need these to run on 30-sec boundaries, keep commands in sync.
    # 在每分钟的第一秒开始执行crontab任务
    * * * * *  sh /etc/vip/check_vip.sh
    # 在每分钟的第30秒开始执行crontab任务
    * * * * * sleep 30; sh /etc/vip/check_vip.sh


    # 4.重启keepalived并查看状态
    systemctl restart keepalived && systemctl enable keepalived && systemctl status keepalived
}


# set check_vip crontab
function set_vncclean_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'check_vip'
  then
    echo "check_vip crontab task has added... delete"
    sed -i '/check_vip/d' /etc/crontab
  fi

  echo "* * * * *  sh /etc/vip/check_vip.sh">>/etc/crontab
  echo "* * * * * sleep 30; sh /etc/vip/check_vip.sh">>/etc/crontab

  systemctl restart crond.service
}


install_keepalived
updata_keepalived
set_vncclean_cron