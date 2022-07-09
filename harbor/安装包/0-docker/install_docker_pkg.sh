#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install docker script path]:" $script_path

REGISTRY_IP=`/sbin/ifconfig | grep inet | grep -v 127.0.0.1 | grep -v inet6 |grep $NETSEG | awk '{print $2}' | tr -d "addr:" | sed -n '1,1p'`


#remove existed docker rpms.
function remove_existed_docker_rpms(){
	dockerResult=`rpm -qa|grep docker`
	echo $dockerResult
	if [ ! -z "$dockerResult" ]
	then
		rpm -e $dockerResult
	fi
}

#install docker
function install_docker_package(){
	echo "sh docker-ce.sh"
	sh ./docker_ce/docker-ce.sh
}


#update docker config.
function update_daemon_json(){
	echo "update docker config."
	mkdir -p /etc/docker
	echo "{
		\"registry-mirrors\":[\"http://hub-mirror.c.163.com\",\"https://registry.docker-cn.com\",\"https://docker.mirrors.ustc.edu.cn\"],
		\"insecure-registries\":[\"$REGISTRY_IP:5000\"],
		\"exec-opts\": [\"native.cgroupdriver=systemd\"],
		\"log-driver\":\"json-file\",
		\"log-opts\":{ \"max-size\" :\"100m\",\"max-file\":\"3\"}
}" >/etc/docker/daemon.json
}

#restart docker daemon.
function restart_docker_daemon(){
	echo "reload docker config and restart docker service."
	systemctl daemon-reload
	systemctl enable docker
	timeout 20 systemctl restart docker
	echo "finish to install docker."
}

#check docker status.
function check_docker_status(){
	sleep 10
	systemctl status docker
	if [ $? -ne 0 ];then
		sleep 20
		systemctl status docker
		if [ $? -eq 0 ];then
			echo "node $hostname docker install success after 1 retry"
		else
			echo "node $hostname docker install failure. Please check $SOTHISAI_MODULE_INSTALL_LOG on node $hostname."
			exit 1
		fi
	fi
}

#check docker service status
if
    systemctl status docker
then
    echo "node $hostname : docker is running, give up install"
else
    echo "node $hostname : start to install docker pkg"
    pkg_path=pkg
    cd $pkg_path
    remove_existed_docker_rpms
    install_docker_package
    cd $script_path
fi

update_daemon_json
restart_docker_daemon
check_docker_status
exit 0
