#!/bin/sh
gDir=/opt/kubernetes/logs
keyDir=/opt/kubernetes/ssl
#,ServiceAccount  SecurityContextDeny
ss=NamespaceLifecycle,NamespaceExists,LimitRanger,DefaultStorageClass,ResourceQuota,ServiceAccount
etcdIps=https://192.168.56.1:2379,https://192.168.56.101:2379,https://192.168.56.102:2379
localIp=192.168.56.1
ipr=121.21.0.0/16
execname=kube-apiserver


cd /opt/kubernetes/amd64/

# --admission-control=$ss  \
# --insecure-bind-address=127.0.0.1  \
#   --runtime-config=rbac.authorization.k8s.io/v1beta1 \

# --feature-gates=CustomResourceValidation=true  # OpenAPI v3 schema 的验证（Validation）机制

nohup ./$execname  \
  --advertise-address=$localIp \
  --bind-address=$localIp \
 --storage-backend=etcd3  \
 --service-cluster-ip-range=$ipr \
 --service-node-port-range=1000-65535 \
--enable-admission-plugins=$ss \
 --kubelet-https=true \
  --authorization-mode=Node,RBAC \
  --runtime-config=rbac.authorization.k8s.io/v1alpha1 \
  --enable-bootstrap-token-auth \
  --token-auth-file=/opt/kubernetes/ssl/token.csv \
 --tls-cert-file=$keyDir/kubernetes.pem \
  --tls-private-key-file=$keyDir/kubernetes-key.pem \
   --cert-dir=$keyDir \
  --client-ca-file=$keyDir/ca.pem \
  --service-account-key-file=$keyDir/ca-key.pem \
  --etcd-cafile=$keyDir/ca.pem \
  --etcd-certfile=$keyDir/kubernetes.pem \
  --etcd-keyfile=$keyDir/kubernetes-key.pem \
   --etcd-servers=$etcdIps  \
  --allow-privileged=true \
 --logtostderr=true \
 --log-dir=$logDir \
 --v=2   >/dev/null 2>$logDir/$execname.log &

echo "==============pid================="
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid
