#!/bin/bash
kpstate=$(ps -ef | grep keepalived | grep -v grep | wc -l)
echo "【keepalived 状态(0-不活跃；非0-活跃)】:" ${kpstate}
if [ "${kpstate}" -eq 0 ]; then
echo 'keepalived 状态不正常'
# 杀掉占用5433端口的PG进程
docker rm -f `docker ps -a|grep "5433"|awk '{print $1}'`
echo '杀掉占用5433端口的PG进程'
fi
