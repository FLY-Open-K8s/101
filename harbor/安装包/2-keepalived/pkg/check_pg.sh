#!/bin/bash
pgstate=$(netstat -na|grep "LISTEN"|grep "5433"|wc -l)
echo "【PG 状态(0-不活跃；非0-活跃)】:" ${pgstate}
if [ "${pgstate}" -eq 0 ]; then
# 使用weight,是否不需要stop??
# 相同weight，VIP漂移在哪里？？
# 检查进程是否存在，如果存在检查联通性，如果联通了。则返回0， 如果不存在或者不联通则返回1  
echo 'PG 状态不正常'
systemctl stop keepalived
fi
