#!/bin/sh

target=/opt/kubernetes/ssl

cd  /opt/kubernetes/json

rm -vrf kubernetes*.pem
echo "================="

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

arr=`ls kubernetes*.pem`
echo  $arr

#cp –f  $arr $target


scp  $arr  cs@node01:$target

scp  $arr  cs@node02:$target

scp  $arr  cs@master02:$target






