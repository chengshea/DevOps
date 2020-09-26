#!/bin/bash

logDir=/opt/kubernetes/logs
cni=/opt/kubernetes/cni
execname=kubelet
localIp=$(ip a | grep 192  | sed  's/\(.*\)\(192\.168\.56\..*\)\/\(.*\)/\2/g')


cd /opt/kubernetes/amd64/

nohup  ./$execname \
  --hostname-override=$localIp \
  --pod-infra-container-image=k8s.org/k8s/pause:3.2 \
  --bootstrap-kubeconfig=/opt/kubernetes/bootstrap.kubeconfig \
  --kubeconfig=/opt/kubernetes/kubelet.kubeconfig \
  --cert-dir=/opt/kubernetes/ssl \
  --cluster-dns=121.21.0.0  --cluster-domain=cluster.local \
  --register-node=true \
  --cni-bin-dir=$cni/bin --cni-conf-dir=$cni/net.d --network-plugin=cni  \
   --runtime-cgroups=/user.slice/user-1000.slice/session-1.scope  \
  --logtostderr=true  \
  --v=2  >/dev/null 2>$logDir/$execname.log  &

echo "==============pid================="
sleep 1s
pid=$(ps -ef |grep $execname | grep -v grep | grep -v $0 |  awk '{print $2}' )
echo $pid


#  --require-kubeconfig \
#  --allow-privileged=true \
#https://v1-18.docs.kubernetes.io/zh/docs/reference/command-line-tools-reference/kubelet/
#已弃用
#   --config=  kubelet将从该文件加载其初始配置。该路径可以是绝对路径，也可以是相对路径
#  --address=$localIp \  
#   --cgroup-driver=cgroupfs  \
#  --cluster-dns=10.254.0.2 \
#  --cluster-domain=cluster.local \
#  --hairpin-mode promiscuous-bridge \
# --kubelet-cgroups=/user.slice/user-1000.slice/session-1.scope \
#  --serialize-image-pulls=false \
#  --container-runtime=docker \