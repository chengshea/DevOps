#!/bin/bash

base_conf=/opt/kubernetes/yaml/tcp
base_data=/opt/data/k8s/redis
nfs_ip=192.168.56.107
redis=1-redis.conf
pv=2-redis_pv.yaml
h_svc=3-headless_service.yaml
pod=4-pod_redis.yaml
svc=5-redis_service.yaml
ingress=6-ingress.yaml
num=6


redis(){
   cat>$1<<EOF
appendonly yes
protected-mode no
cluster-enabled yes
cluster-config-file /var/lib/redis/nodes.conf
cluster-node-timeout 5000
cluster-announce-port 6379
cluster-announce-bus-port 16379
dir /var/lib/redis
port 6379
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
  replicas: $2
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
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--cluster-announce-ip"
          - "\$(MY_POD_IP)"
        env:
        - name: MY_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
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
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
  #自动为每个Pod创建一个PVC,创建出来的PVC名称-1-2            
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
    [ "2-redis_pv.yaml" != "${arr[i]}" ] || { echo "persistentvolume redis-pv 不删除" && continue;}
    #kubectl delete -n default configmap redis-conf
    [ "1-redis.conf" != "${arr[i]}" ] || { echo "configmap redis-conf 不删除" && continue;}
      kubectl delete -f  ${arr[i]}
  done
}

create(){
  for i in $@; do
    echo "开始生成:"$i   ${i:2:0-5}

    if [ "2-redis_pv.yaml" == "$i" ];then
        for (( t = 0; t <= ${num}; t++ )); do
           [ 1 -eq "$t" ] && { echo "清空文件..." && echo "">${i};}
           ${i:2:0-5}  $i  $t
        done 
    else
        ${i:2:0-5}  $i
    fi

    [ -f "$i" ] || { echo "没有生成$i,退出" && exit 1; }
     # && kubectl create configmap redis-conf --from-file=$i
    [ "1-redis.conf" != "$i" ] || { echo "创建configmap..." &&   continue;}
    echo "apply...."
    kubectl apply -f  $i
  done

}

[ -f "$base_conf/v1" ] || { echo "没有目录,创建目录..." && mkdir -p $base_conf/v1 ; }
cd  $base_conf/v1

arr=($redis $pv $h_svc $pod $svc $ingress)

del  ${#arr[@]}  ${arr[@]} 

#create ${arr[@]}


:<<EOF
cat EOF中出现$变量通常会直接被执行，显示执行的结果。
若想保持$变量不变需要使用 \ 符进行注释,或  直接在第一个EOF上加上双引号


一个完整的StatefulSet应用由三个部分组成： headless service、StatefulSet controller、volumeClaimTemplate;Headless service是StatefulSet实现稳定网络标识的基础

EOF