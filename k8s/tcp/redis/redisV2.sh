#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

base_conf=$DIR/v2
#nfs路径
base_data=/opt/data/k8s/redis
nfs_ip=192.168.56.107
redis=1-redis.conf
srcipt=2-sh_pv.yaml
pv=3-redis_pv.yaml
h_svc=4-headless_service.yaml
pod=5-pod_redis.yaml
svc=6-redis_service.yaml
ingress=7-ingress.yaml
num=6


redis(){
   cat>$1<<EOF
appendonly yes
#默认yes,不允许外网访问
protected-mode no
#指定ip访问
#bing 192.168.56.1 192.168.56.107
cluster-enabled yes
cluster-config-file /var/lib/redis/nodes.conf
cluster-node-timeout 5000
cluster-announce-port 6379
#总线10000+端口号
cluster-announce-bus-port 16379
dir /var/lib/redis
port 6379
EOF

}

sh_pv(){
      cat>>$1<<EOF
#pv-pvc
----
kind: PersistentVolume
apiVersion: v1
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 7Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: $nfs_ip
    path: "$base_data/srcipt/"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pvc-claim
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 7Mi
  storageClassName: manual
EOF
}

redis_pv(){
    cat>>$1<<EOF
--- 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv$2
spec:
  capacity:
    storage: 200M
  accessModes:
    - ReadWriteMany
  nfs:
    server: $nfs_ip
    path: "$base_data/pv$2"

EOF

}



headless_service(){
   cat>$1<<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: redis-headless-service
  labels:
    app: redis
spec:
  ports:
  - name: redis-port
    port: 6379
  clusterIP: None
  selector:
    app: redis
    appCluster: redis-cluster
EOF

}


pod_redis(){
	cat>$1 <<EOF
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-app
spec:
  serviceName: "redis-headless-service"
  replicas: $num
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        appCluster: redis-cluster
    spec:
      terminationGracePeriodSeconds: 20
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - redis
              topologyKey: kubernetes.io/hostname
      containers:
      - name: redis
        image: k8s.org/cs/redis:6.0.6-buster
        command:
          - "/sh/start.sh"
        args:
          - "/etc/redis/redis.conf"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
          - name: check-ip
            mountPath: "/sh"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: check-ip
        persistentVolumeClaim:
          claimName: task-pvc-claim
          readOnly: false
  #自动为每个Pod创建一个PVC,创建出来的PVC名称-1-2...            
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 200M
EOF
}


redis_service(){
     cat>$1<<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  labels:
    app: redis
spec:
  ports:
  - name: redis-port
    protocol: "TCP"
    port: 6379
    targetPort: 6379
  selector:
    app: redis
    appCluster: redis-cluster
EOF
}

#解析到 Traefik 所在的节点(例如node03) $redis-cli -h node03
ingress(){
  cat>$1<<"EOF"
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: redis
spec:
  entryPoints:
    - redis
  routes:
  - match: HostSNI(`*`) 
    services:
    - name: redis-service
      port: 6379
EOF
}


del(){
  for i in $(seq $1 -1 0); do
    echo ${arr[i]}
    [ "2-sh_pv.yaml" != "${arr[i]}" ] || { echo "persistentvolume sh-pv 不删除" && continue;}
    echo "apply....$i"
    [ "3-redis_pv.yaml" != "${arr[i]}" ] || { echo "persistentvolume redis-pv 不删除" && continue;}
    #kubectl delete -n default configmap redis-conf
    [ "1-redis.conf" != "${arr[i]}" ] || { echo "configmap redis-conf 不删除" && continue;}
      kubectl delete -f  ${arr[i]}
  done
}

create(){
  for i in $@; do
    echo "开始生成:"$i   ${i:2:0-5}
    yml=$base_conf/$i
    if [ "3-redis_pv.yaml" == "$i" ];then
        for (( t = 0; t <= ${num}; t++ )); do
           [ 1 -eq "$t" ] && { echo "清空文件..." && echo "">${yml};}
           ${i:2:0-5}  $yml  $t
        done 
    else
        ${i:2:0-5}  $yml
    fi

    [ -f "$yml" ] || { echo "没有生成$yml,退出" && exit 1; }
     # && kubectl create configmap redis-conf --from-file=$i
    [ "1-redis.conf" != "$i" ] || { echo "创建configmap..." &&   continue;}
    [ "2-sh_pv.yaml" != "$i" ] || { echo "创建persistentvolume sh-pv ..." && continue;}
    [ "3-redis_pv.yaml" != "$i" ] || { echo "创建persistentvolume redis-pv ..." && continue;}
    echo "apply....$i"
    #kubectl apply -f  $i
  done

}

[ -f "$base_conf" ] || { echo "没有目录,创建目录..." && mkdir -p $base_conf ; }

arr=($redis $srcipt $pv $h_svc $pod $svc $ingress)

#del  ${#arr[@]}  ${arr[@]} 

create ${arr[@]}


:<<EOF
k8s因为某种原因导致重启(断电),pod的ip发生变化,pod启动后执行脚本更新node.conf的ip

EOF