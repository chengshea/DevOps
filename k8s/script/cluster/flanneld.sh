#!/bin/bash

logDir=/opt/kubernetes/logs
execname=flanneld
baseFile=/opt/kubernetes/ssl
masterIp=https://192.168.56.1:2379
node01Ip=https://192.168.56.101:2379
node02Ip=https://192.168.56.108:2379
iname=$(ip add | grep 192.168.56. | awk '{print $7}')

cd /opt/kubernetes/amd64/

export ETCDCTL_API=2

nohup ./$execname \
  --etcd-endpoints=$masterIp,$node02Ip,$node02Ip \
  --iface=$iname   \
  --etcd-prefix=/atomic.io/network   \
   -etcd-cafile=$baseFile/ca.pem  \
   -etcd-certfile=$baseFile/kubernetes.pem  \
   -etcd-keyfile=$baseFile/kubernetes-key.pem \
   >/dev/null 2>$logDir/$execname.log  &

echo "==============pid================="
sleep 1s
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid