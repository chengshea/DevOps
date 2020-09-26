
#!/bin/bash

logDir=/opt/kubernetes/logs/
url=http://127.0.0.1:8080
execname=kube-controller-manager

cd /opt/kubernetes/amd64/




nohup ./$execname  \
  --master=$url   \
  --logtostderr=true \
  --log-dir=$logDir \
  --v=2   >/dev/null 2>$logDir/controller-manager-log &


echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid