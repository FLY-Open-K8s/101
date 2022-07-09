#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`

echo "clean containers ..."
docker rm -f $(docker ps -q -a)

echo "uninstall docker pkg"
service docker stop
dockerResult=`rpm -qa|grep docker`
echo $dockerResult
if [ ! -z "$dockerResult" ];then
    rpm -e $dockerResult
    if [ $? -eq 0 ];then
        ip link delete docker0
        rm -rf /usr/lib/systemd/system/docker.service.d
        rm -rf /var/lib/docker
        rm -rf /var/run/docker
        echo "uninstall docker success"
    else
        echo "uninstall docker failure"
        exit 1
    fi
else
    echo "docker has been uninstalled"
fi
echo " try to remove docker group ..."
if
	! groupdel docker
then
	echo "Failed to remove docker group!"
fi
exit 0