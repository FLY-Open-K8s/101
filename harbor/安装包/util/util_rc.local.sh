#!/bin/bash
#public
function config_rclocal(){
    rcfile=/etc/rc.d/rc.local
    if
        nvidia-smi > /dev/null
    then
        onstart_nv_gpu_driver
    fi
    onstart_iptables_forward
    chmod +x $rcfile
}

#private
function onstart_nv_gpu_driver(){
	if
		! grep "nvidia-smi -pm 1" $rcfile >/dev/null
	then
		echo "nvidia-smi -pm 1" >>$rcfile
	fi
}

#private
function onstart_iptables_forward(){
    iptables -P FORWARD ACCEPT
    # exec when Linux start
    ## check and write rc.local
    if
        ! cat $rcfile|grep "iptables -P FORWARD ACCEPT" > /dev/null
    then
        log_module_install "add iptables FORWARD into $rcfile"
        echo "iptables -P FORWARD ACCEPT" >> $rcfile
    fi

}
config_rclocal