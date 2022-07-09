#!/bin/bash
LOG_PREFIX=/var/log

#SothisAI Server
SOTHISAI_SERVER_INSTALL_LOG=$LOG_PREFIX/sothisai_server_install.log
function log_sothisai_server_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_SERVER_INSTALL_LOG
}
function init_log_sothisai_server_install(){
    init_log $SOTHISAI_SERVER_INSTALL_LOG
}

#K8S
SOTHISAI_K8S_SERVER_INSTALL_LOG=$LOG_PREFIX/sothisai_k8s_server_install.log
function log_k8s_server_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_K8S_SERVER_INSTALL_LOG
}
function init_log_k8s_server_install(){
    init_log $SOTHISAI_K8S_SERVER_INSTALL_LOG
}

SOTHISAI_K8S_CLIENT_INSTALL_LOG=$LOG_PREFIX/sothisai_k8s_client_install.log
function log_k8s_client_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_K8S_CLIENT_INSTALL_LOG
}
function init_log_k8s_client_install(){
    init_log $SOTHISAI_K8S_CLIENT_INSTALL_LOG
}

#SLURM
SOTHISAI_SLURM_SERVER_INSTALL_LOG=$LOG_PREFIX/sothisai_slurm_server_install.log
function log_slurm_server_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_SLURM_SERVER_INSTALL_LOG
}
function init_log_slurm_server_install(){
    init_log $SOTHISAI_SLURM_SERVER_INSTALL_LOG
}

SOTHISAI_SLURM_NODE_INSTALL_LOG=$LOG_PREFIX/sothisai_slurm_node_install.log
function log_slurm_node_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_SLURM_NODE_INSTALL_LOG
}
function init_log_slurm_node_install(){
    init_log $SOTHISAI_SLURM_NODE_INSTALL_LOG
}

#Module
SOTHISAI_MODULE_INSTALL_LOG=$LOG_PREFIX/sothisai_module_install.log
function log_module_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_MODULE_INSTALL_LOG
}
function init_log_module_install(){
    init_log $SOTHISAI_MODULE_INSTALL_LOG
}

:<<!
#Registry
SOTHISAI_REGISTRY_INSTALL_LOG=$LOG_PREFIX/sothisai_registry_install.log
function log_registry_install(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_REGISTRY_INSTALL_LOG
}
function init_log_registry_install(){
    init_log $SOTHISAI_REGISTRY_INSTALL_LOG
}

#update platform
SOTHISAI_UPDATE_PLATFORM_LOG=$LOG_PREFIX/sothisai_update_platform.log
function log_update_platform(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_UPDATE_PLATFORM_LOG
}
function init_log_update_platform(){
    init_log $SOTHISAI_UPDATE_PLATFORM_LOG
}
#update scripts
SOTHISAI_UPDATE_SCRIPTS_LOG=$LOG_PREFIX/sothisai_update_scripts.log
function log_update_scripts(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_UPDATE_SCRIPTS_LOG
}
function init_log_update_scripts(){
    init_log $SOTHISAI_UPDATE_SCRIPTS_LOG
}
#sync scripts
SOTHISAI_SYNC_SCRIPTS_LOG=$LOG_PREFIX/sothisai_sync_scripts.log
function log_sync_scripts(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_SYNC_SCRIPTS_LOG
}
function init_log_sync_scripts(){
    init_log $SOTHISAI_SYNC_SCRIPTS_LOG
}
#update slurm etc
SOTHISAI_UPDATE_SLURM_ETC_LOG=$LOG_PREFIX/sothisai_update_slurm_etc.log
function log_update_slurm_etc(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_UPDATE_SLURM_ETC_LOG
}
function init_log_update_slurm_etc(){
    init_log $SOTHISAI_UPDATE_SLURM_ETC_LOG
}
#sync slurm etc
SOTHISAI_SYNC_SLURM_ETC_LOG=$LOG_PREFIX/sothisai_sync_slurm_etc.log
function log_sync_slurm_etc(){
    echo -e "[`date`] $1" | tee -ia  $SOTHISAI_SYNC_SLURM_ETC_LOG
}
function init_log_sync_slurm_etc(){
    init_log $SOTHISAI_SYNC_SLURM_ETC_LOG
}
!

#private common
function init_log(){
	local log_path=$1
	if [ -f "$log_path" ];then
		#bak
        mv $log_path "${log_path}_`date +%Y%m%d_%H%M`"
	fi
}