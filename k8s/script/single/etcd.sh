#!/bin/bash

logDir=/opt/kubernetes/logs
execname=etcd

cd /opt/kubernetes/etcd-v3.4.3-linux-amd64/

#-listen-client-urls  用于指定etcd和客户端的连接端口
#-advertise-client-urls  用于指定etcd服务器之间通讯的端口 etcd有要求，如果-listen-client-urls被设置了，那么就必须同时设置-advertise-client-urls，所以即使设置和默认相同，也必须显式设置.

nohup ./$execname \
  --data-dir ./data.etcd/  \
  --listen-client-urls http://127.0.0.1:2379 \
  --advertise-client-urls http://127.0.0.1:2379  \
   >/dev/null 2>$logDir/etcd.log  &

echo "==============pid================="
#grep -v 'grep\|etcd.sh'
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid