
#!/bin/bash

logDir=/opt/kubernetes/logs/
keyDir=/opt/kubernetes/ssl

url=http://127.0.0.1:8080
execname=kube-controller-manager

cd /opt/kubernetes/amd64/




nohup ./$execname  \
  --master=$url   \
  --cluster-name=kubernetes \
  --allocate-node-cidrs =true \
  --cluster-cidr=121.21.0.0/16 \
  --cluster-signing-cert-file=$keyDir/ca.pem \
  --cluster-signing-key-file=$keyDir/ca-key.pem \
  --service-account-private-key-file=$keyDir/ca-key.pem \
  --root-ca-file=$keyDir/ca.pem \
  --log-dir=$logDir \
    --logtostderr=true \
  --v=2   >/dev/null 2>$logDir/$execname.log &


echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid