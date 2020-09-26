#!/bin/bash

logDir=/opt/kubernetes/logs
baseFile=/opt/kubernetes/ssl
execname=etcd
#localIp=$(echo `hostname -I` | sed  's/\(.*\)\(192\.168.*[[:space:]]\)\(.*\)/\2/g')
localName=$(hostname)

masterIp=https://192.168.56.1
node01Ip=https://192.168.56.101
node02Ip=https://192.168.56.108

eval localIp=$(echo '$'"$localName"Ip)

echo $localName:$localIp

cd /opt/kubernetes/etcd/


:<<EOF   
#-listen-client-urls  用于指定etcd和客户端的连接端口
#-advertise-client-urls  用于指定etcd服务器之间通讯的端口 etcd有要求，如果-listen-client-urls被设置了，那么就必须同时设置-advertise-client-urls，所以即使设置和默认相同，也必须显式设置.
EOF

nohup ./$execname \
  --name $localName \
  --cert-file=$baseFile/kubernetes.pem \
  --key-file=$baseFile/kubernetes-key.pem \
  --peer-cert-file=$baseFile/kubernetes.pem \
  --peer-key-file=$baseFile/kubernetes-key.pem  \
  --trusted-ca-file=$baseFile/ca.pem \
  --peer-trusted-ca-file=$baseFile/ca.pem \
  --initial-advertise-peer-urls $localIp:2380 \
  --listen-peer-urls $localIp:2380 \
  --listen-client-urls $localIp:2379,http://127.0.0.1:2379 \
  --advertise-client-urls $localIp:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster master=$masterIp:2380,node01=$node01Ip:2380,node02=$node02Ip:2380 \
   --initial-cluster-state new  \
   --enable-v2=true   \
   --data-dir ./data.etcd/  >/dev/null 2>$logDir/etcd.log  &


echo "==============pid================="
sleep 1s
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid