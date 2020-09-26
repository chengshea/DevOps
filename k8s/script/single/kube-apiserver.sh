
#!/bin/bash

logDir=/opt/kubernetes/logs
keyDir=/opt/kubernetes/key
#,ServiceAccount
ss=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,DefaultStorageClass,ResourceQuota
sIP=http://127.0.0.1:2379
port=8080
ipr=10.10.10.0/24
execname=kube-apiserver


cd /opt/kubernetes/amd64/



nohup ./$execname  \
 --storage-backend=etcd3  \
 --etcd-servers=$sIP  \
 --insecure-bind-address=0.0.0.0  \
 --insecure-port=$port \
 --service-cluster-ip-range=$ipr \
 --service-node-port-range=1-65535 \
 --admission-control=$ss  \
 --logtostderr=true \
 --log-dir=$logDir \
 --cert-dir=$keyDir \
 --v=2   >/dev/null 2>$logDir/api-log &

echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid