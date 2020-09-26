#!/bin/bash
baseFile=/opt/kubernetes/ssl

masterIp=https://192.168.56.1:2379
node01Ip=https://192.168.56.101:2379
node02Ip=https://192.168.56.108:2379

cd /opt/kubernetes/etcd

:<<!

ETCDCTL_API=2 ./etcdctl \
--endpoints=$masterIp,$node01Ip,$node02Ip \
--cert-file=$baseFile/ca.pem --cert-file=$baseFile/kubernetes.pem --key-file=$baseFile/kubernetes-key.pem \
get /atomic.io/network/config '{ "Network": "121.21.0.0/16" }'


#etcdctl --ca-file=ca.pem --cert-file=kubernetes.pem --key-file=kubernetes-key.pem --endpoints="https://192.168.56.1:2379,https://192.168.56.101:2379,https://192.168.56.102:2379" set  /atomic.io/network/config '{ "Network": "121.21.0.0/16", "Backend": {"Type": "vxlan"}}'


ETCDCTL_API=2 ./etcdctl \
 --write-out=table \
--cacert=$baseFile/ca.pem --cert=$baseFile/kubernetes.pem --key=$baseFile/kubernetes-key.pem \
--endpoints=$masterIp,$node01Ip,$node02Ip \
endpoint health




!

ETCDCTL_API=3 ./etcdctl \
 --write-out=table \
--cacert=$baseFile/ca.pem --cert=$baseFile/kubernetes.pem --key=$baseFile/kubernetes-key.pem \
--endpoints=$masterIp,$node01Ip,$node02Ip \
endpoint status
