#!/bin/bash
baseFile=/opt/kubernetes/ssl

masterIp=https://192.168.56.1:2379
node01Ip=https://192.168.56.101:2379
node02Ip=https://192.168.56.108:2379
prefix=/atomic.io/network/config

temp='{ "Network": "121.21.0.0/16", "Backend": {"Type": "vxlan"}}'

exec(){
    arr=$@
    cd /opt/kubernetes/etcd

	ETCDCTL_API=2  ./etcdctl --ca-file=$baseFile/ca.pem \
	  --cert-file=$baseFile/kubernetes.pem \
	  --key-file=$baseFile/kubernetes-key.pem \
	  --endpoints=$masterIp,$node01Ip,$node02Ip \
	  $arr
}
 
#查询值
exec get $prefix

#启动 flanneld 需要先设置数据
exec set $prefix  $temp

#删除
#exec rmdir $prefix


#启动 flanneld 需要先设置数据
#exec  set '{ "Network": "121.21.0.0/16", "Backend": {"Type": "vxlan"}}'

:<<EOF
Couldn't fetch network config: client: response is invalid json. The endpoint is probably not valid etcd cluster endpoint.
v0.12.0 不支持 etcd3

root@node01:/opt/kubernetes/script# cat /opt/kubernetes/ssl/subnet.env
DOCKER_OPT_BIP="--bip=121.21.56.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=true"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=121.21.56.1/24 --ip-masq=true --mtu=1472"

root@node01:/opt/kubernetes/script# vi /lib/systemd/system/docker.service
#修改为下面显示部分
root@node01:/opt/kubernetes/script# cat /lib/systemd/system/docker.service | grep -C 1  EnvironmentFile
# for containers run by docker
EnvironmentFile=/opt/kubernetes/ssl/subnet.env
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS -H fd:// --containerd=/run/containerd/containerd.sock
#重启docker
systemctl restart docker
  
 


#查询状态
ETCDCTL_API=3 /opt/kubernetes/etcd/etcdctl  --write-out=table \
--cacert=$baseFile/ca.pem --cert=$baseFile/kubernetes.pem --key=$baseFile/kubernetes-key.pem \
--endpoints=$masterIp,$node01Ip,$node02Ip \
endpoint status


EOF