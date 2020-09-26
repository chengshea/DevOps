#!/bin/bash

logDir=/opt/kubernetes/logs
keyDir=/opt/kubernetes/
sIP=http://127.0.0.1:2379
port=8080
execname=kube-proxy

cd /opt/kubernetes/amd64/



nohup ./$execname  \
 --bind-address=127.0.0.1  \
 --kubeconfig=$keyDir/proxy.kubeconfig \
 --logtostderr=true \
  --hostname-override=172.30.200.21 \
  --cluster-cidr=10.198.1.1/21 \
  --log-dir=$logDir \
  --v=2  >/dev/null 2>$logDir/proxy-log &

echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid