#!/bin/bash
if [ $# -ne 3 ];then
	echo "Usage : $0 nodelist_file source_file target_folder"
	exit 1
fi
nodelist_file="$1"
source_file="$2"
target_folder="$3"

num=${RANDOM}_`date +%s`
resFolder=/tmp/sothisai/pscp_$num
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

#pscp
pscp -r -p $batch_num -t $exec_timeout -O PasswordAuthentication=no -O NumberOfPasswordPrompts=0 -O ConnectTimeout=$connect_timeout -h $nodelist_file -o $output_path -e $errput_path $source_file $target_folder

#result
echo OUTPUT_PSCP_FOLDER:$output_path
echo ERROR_PSCP_FOLDER:$errput_path

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
