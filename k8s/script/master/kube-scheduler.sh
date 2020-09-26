
#!/bin/bash

logDir=/opt/kubernetes/logs/
keyDir=/opt/kubernetes/ssl
url=http://127.0.0.1:8080

execname=kube-scheduler

cd /opt/kubernetes/amd64/




nohup ./$execname  \
   --master=$url   \
   --cert-dir=$keyDir \
   --leader-elect=true   \
   --logtostderr=true \
   --log-dir=$logDir --v=2   >/dev/null 2>$logDir/$execname.log &

echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid