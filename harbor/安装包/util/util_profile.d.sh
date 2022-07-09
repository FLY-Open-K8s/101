#!/bin/bash

#Parameters that need to be initialized:
#sothisai_home
#log_path

#update dawning_env
#public
function update_dawning_env(){
	log_sothisai_install_util "update dawning env ...."
	env_path=/etc/profile.d/dawning.sh
	#update SOTHISAI_HOME
	update_special_env SOTHISAI_HOME $sothisai_home
	#update GRIDVIEW_HOME
	update_special_env GRIDVIEW_HOME $sothisai_home
	
	source $env_path
}

#private
function update_special_env(){
	local key=$1
	local value=$2
	if
		cat $env_path |grep -v '^#' |grep "$key" >/dev/null
	then
		#replace
		sed -i "s:$key=.*:$key=$value:" $env_path
	else
		#add
		echo "export $key=$value" >> $env_path
	fi
}

#private
function log_sothisai_install_util(){
	echo -e "[`date`] $1" | tee -ia  $log_path
}

