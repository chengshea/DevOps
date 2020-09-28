#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

base_file=$DIR/test
crd=1-crd.yaml
rbac=2-rbac.yaml
role=3-role.yaml
static=4-static_config.yaml
dynamic=5-dynamic_toml.toml
deploy=6-deploy.yaml
svc=7-service.yaml
ingress=8-ingress.yaml


y_crd(){
	cat >$1 <<EOF
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutes.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRoute
    plural: ingressroutes
    singular: ingressroute
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: middlewares.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: Middleware
    plural: middlewares
    singular: middleware
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutetcps.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRouteTCP
    plural: ingressroutetcps
    singular: ingressroutetcp
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressrouteudps.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRouteUDP
    plural: ingressrouteudps
    singular: ingressrouteudp
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: tlsoptions.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TLSOption
    plural: tlsoptions
    singular: tlsoption
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: tlsstores.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TLSStore
    plural: tlsstores
    singular: tlsstore
  scope: Namespaced

---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: traefikservices.traefik.containo.us

spec:
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TraefikService
    plural: traefikservices
    singular: traefikservice
  scope: Namespaced

EOF

}



y_rbac(){
	cat>$1 <<EOF
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller

rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - persistentvolumes
    verbs:
      - get
      - list
      - watch
      - create  # persistentvolumes
      - delete
  - apiGroups:
      - ""
    resources:
      - persistentvolumeclaims
    verbs:
      - get
      - list
      - watch
      - update  # persistentvolumeclaims         
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
    resources:
      - middlewares
      - ingressroutes
      - traefikservices
      - ingressroutetcps
      - ingressrouteudps
      - tlsoptions
      - tlsstores
    verbs:
      - get
      - list
      - watch
EOF

}



y_role(){
   cat >$1 <<EOF
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: traefik-ingress-controller
EOF

}

#静态配置动态文件======================?
y_static_config(){
   cat >$1 <<EOF
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: traefik-config-yaml
  namespace: kube-system
data:
  traefik.yaml: |-
    ping: ""
    serversTransport:
      insecureSkipVerify: true
    api:
      insecure: true
      dashboard: true
      debug: false
    metrics:
      prometheus: ""
    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
      redis:
        address: ":6379"
    providers:
      kubernetesCRD: ""
      kubernetesIngress: ""
      file:
        directory: /etc/conf.d/
        watch: true
    log:
      filePath: ""
      level: error 
      format: json
    accessLog:
      filePath: ""
      format: json
      bufferingSize: 0
      filters:
        #statusCodes: ["200"]
        retryAttempts: true
        minDuration: 20
      fields:
        defaultMode: keep
        names:
          ClientUsername: drop  
        headers:
          defaultMode: keep
          names:
            User-Agent: redact
            Authorization: drop
            Content-Type: keep
EOF

}


genkey(){
openssl req \
        -newkey rsa:2048 -nodes -keyout tls.key \
        -x509 -days 3650 -out tls.crt \
        -subj "/C=CN/ST=GD/L=SZ/O=cs/OU=shea/CN=k8s.org" 
}

y_dynamic_toml(){
   cat >$1 <<EOF
defaultEntryPoints = ["http","https"]
[entryPoints]
  [entryPoints.http]
  address = ":80"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      CertFile = "/ssl/tls.crt"
      KeyFile = "/ssl/tls.key"


tls:
  certificates:
    - certFile: /path/to/domain.cert
      keyFile: /path/to/domain.key
      stores: #stores 列表将被忽略，并自动设置为 ["default"]
        - default

EOF
}




y_deploy(){
   cat >$1 <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
  labels:
    app: traefik
spec:
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      name: traefik
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 1
      #设置node筛选器，在特定label的节点上启动  kubectl label node 192.168.56.109 tklabel=ok
      nodeSelector: 
         tklabel: "ok"
      containers:
        - image: k8s.org/k8s/traefik:v2.2.10
          name: traefik
          ports:
            - name: web
              containerPort: 80
              hostPort: 80         ## 将容器端口绑定所在服务器的 80 端口
            - name: websecure
              containerPort: 443
              hostPort: 443        ## 将容器端口绑定所在服务器的 443 端口
            - name: redis
              containerPort: 6379
              hostPort: 6379
            - name: admin
              containerPort: 8080  ## Traefik Dashboard 端口
          resources:
            limits:
              cpu: 200m
              memory: 256Mi
            requests:
              cpu: 100m
              memory: 256Mi
          securityContext:
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
          args:
            - --configfile=/config/traefik.yaml
          volumeMounts:
            - mountPath: "/config"
              name: "config"
            - mountPath: "/ssl"
              name: "ssl"
      volumes:
        - name: config
          configMap:
            name: traefik-config-yaml
        - name: ssl
          secret:
            secretName: traefik-cert
EOF

}




y_service(){
   cat >$1 <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  ports:
    - name: web
      port: 80
    - name: websecure
      port: 443
    - name: admin
      port: 8080
  selector:
    app: traefik

EOF
}




y_ingress(){
   cat >$1 <<"EOF"
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard-route
  namespace: kube-system
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`node03`)
      kind: Rule
      services:
        - name: traefik
          port: 8080

EOF

}

[ -d "$base_file" ] || { echo "没有目录,则创建目录" && mkdir $base_file; }
[ -n "$(which openssl)"] || { echo "需要用到openssl,没有找到,退出" && exit 1; }
cd $base_file

# genkey  
# [ -f "tls.key" ] || { echo "没有生成密钥,退出" && exit 1; }
#kubectl create secret generic traefik-cert --from-file=tls.crt --from-file=tls.key -n kube-system
# #kubectl create configmap traefik-conf --from-file=$dynamic -n kube-system

arr=($crd $rbac $role $static $dynamic $deploy  $svc $ingress)

for i in ${arr[@]}; do
echo "开始生成:"$i 
y_${i:2:0-5}  $i
[ -f "$i" ] || { echo "没有生成$i,退出" && exit 1; }
#kubectl apply -f  $i
done



