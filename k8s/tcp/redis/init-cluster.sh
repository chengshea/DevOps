#!/bin/sh

arr=($(kubectl get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP}:6379 '))
echo ${arr[@]}

master=$(echo ${arr[@]}|awk '{print $1" "$2" "$3}')
echo "指定主节点:$master"
echo "yes" | kubectl exec -it redis-app-2 -- redis-cli --cluster create $master

for i in $(seq 3 +1 5); do
	echo "添加从节点:"${arr[i]}  ${arr[0]}
	echo "yes" | kubectl exec -it redis-app-2 -- redis-cli --cluster add-node  ${arr[i]}  ${arr[0]} --cluster-slave
done


:<<EOF
====echo ${arr[@]}|tr -s ' '|cut -d' ' -f2
==tr 
-s 即将重复出现字符串，只保留第一个
==cut 
-d 以什么为分割符
-f 第几个
组合等于   awk '{print $2}'

=====jsonpath='{range.items[:3]}{.status.podIP}:6379 '
items[:3]   取前3
=====jsonpath="{range.items[$i,0]}{.status.podIP}:6379 "
双引号传变量
EOF