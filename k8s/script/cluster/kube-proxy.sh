#!/bin/bash

logDir=/opt/kubernetes/logs
keyDir=/opt/kubernetes/
localIp=$(ip a | grep 192  | sed  's/\(.*\)\(192\.168\.56\..*\)\/\(.*\)/\2/g')
execname=kube-proxy

cd /opt/kubernetes/amd64/



nohup ./$execname  \
 --bind-address=$localIp  \
  --hostname-override=$localIp \
  --cluster-cidr=121.21.0.0/16 \
  --proxy-mode=ipvs \
  --ipvs-scheduler=nq \
 --kubeconfig=$keyDir/kube-proxy.kubeconfig \
  --logtostderr=true \
  --v=2  >/dev/null 2>$logDir/$execname.log &

echo "==============pid================="
sleep 1s
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid