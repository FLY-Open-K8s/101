#!/bin/bash
if [ $# -ne 2 ];then
	echo "Usage : $0 nodelist_file cmd"
	exit 1
fi
nodelist_file="$1"
cmd="$2"

num=${RANDOM}_`date +%s`
resFolder=/tmp/sothisai/pssh_$num
echo "Reslut Folder : "+$resFolder
mkdir -p $resFolder

output_path=$resFolder/out
errput_path=$resFolder/err

#batch exec num
batch_num=100
#total exec time: default ulimit
exec_timeout=0
#ssh no responds timeout
connect_timeout=5

#pssh
pssh -p $batch_num -t $exec_timeout -O PasswordAuthentication=no -O NumberOfPasswordPrompts=0 -O ConnectTimeout=$connect_timeout -h $nodelist_file -o $output_path -e $errput_path $cmd

#result
echo OUTPUT_PSSH_FOLDER:$output_path
echo ERROR_PSSH_FOLDER:$errput_path

#print out
function printout(){
	local tOutFolder=$1
	local tErrFolder=$2
	echo ========OUTPUT:
	for i in `ls $tOutFolder`
	do
		if [ -s "$tOutFolder/$i" ];then
			echo NODES:$i
			cat $tOutFolder/$i
		fi
	done
	echo ========ERROR:
	for i in `ls $tErrFolder`
        do
                if [ -s "$tErrFolder/$i" ];then
					echo NODES:$i
			cat $tErrFolder/*
		fi
	done
}
#printout $output_path $errput_path
