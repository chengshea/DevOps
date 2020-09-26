#!/bin/sh

cd  /opt/kubernetes/json/



cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

