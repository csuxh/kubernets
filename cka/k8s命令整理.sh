1. master参与调度 kubectl taint node k8s-master node-role.kubernetes.io/master-
 node selector： kubectl label nodes jack-node type=mysql-server

2. deployment
kubectl run jackhttpd-deploy --image=csuxh/jackhttpd:v1.0 --replicas=2
扩容缩容：kubectl scale deploy/jackhttpd --replicas=4

kubectl run --image=busybox my-deploy1 -o yaml --dry-run

3. service 
kubectl expose deployment/jackhttpd-deploy --type=NodePort/ClusterIP --name=httpd-service --port=80 (--target-port=9999)

kubectl api-versions


4. proxy:
kubectl proxy --port=8080
curl  -s localhost:8080  I jq items[] .metadata .name

5. label:
kubectl label service/jackhttpd-service version=v1  （--overwrite）
kubectl label service/jackhttpd-service version- (删除label)
# Update all pods in the namespace
 kubectl label pods --all status=unhealthy
 高级筛选：
 matchLaels/ matchExpressions(In/Exists/DosNotExist/NotIn)

 nodeSelector:

注解：annotation 不能作为标签选择器
kubectl  annotate svc/jackhttpd-service created-by="jack.xia"

6. POD生命周期
initContainer
spec.lifecycle: postStart/preStop 
存活性探测： spec.livenessProbe  readinessProbe
ExecAction, TCPSocketAction, HTTPGetAction
(restartPolicy: Always/OnFailure/NEVER)

spec:
  containers:
  - name: liveness-exec-demo
    image: busybox:1.31.0
    imagePullPolicy: IfNotPresent
    args: ["/bin/sh", "-c", "touch /tmp/healthy; sleep 60; rm -rf /tmp/healthy; sleep 100"]
    livenessProbe:
      exec:
        command: ["test", "-e", "/tmp/healthy"]
    livenessProbe:
      httpGet:
        path: /healthz
        port: httpd
        scheme: HTTP
     livenessProbe:
      tcpSocket:
        port: httpd
其它属性：
initialDelaySeconds: default 0s
timeoutSeconds: 1s
periodSeconds: 10s
successThreshold: 1  failureThreshold: 3

就绪性探测：readinessProbe
(生产环境中由于应用启动需要时间，必须定义就绪性探测机)


资源需求和限制：

Qos Class:
Guaranteed
Burstable
BestEffort


7. POD控制器：
ReplicaSet
kubectl get pods -1 app=rs-demo -o \
custom columns=Name:metadata name,Image:spec . conta 工ners[OJ .image

kubectl scale replicasets rs-example --current-replcas = 2 --replicas=4
kubectl delete replicasets rs-sample --cascade=false(保留pod)

Deployment控制器：
更新：
kubectl patch deploy/jackhttpd -p '{"spec": {"minReadySeconds": 5}}'
kubectl set image deploy/jackhttpd jackhttpd=csuxh/jackhttpd:v1.1
kubectl rollout status deploy/jackhttpd

金丝雀发布(Canary Release)： pause/resume  maxSurge,maxUnavailable 部分更新, pause之后验证，再恢复完成更新
kubectl patch deploy/jackhttpd -p '{"spec": {"strategy": {"rollingUpdate": {"maxSurge": 1, "maxUnavailable": 0}}}}'

发布： kubectl set image deploy/jackhttpd jackhttpd=csuxh/jackhttpd:v1.3 && kubectl rollout pause deploy/jackhttpd  
kubectl rollout resume deploy/jackhttpd
回滚：kubectl rollout history deploy/jackhttpd
kubectl rollout undo deploy/jackhttpd --to-revision=2 (默认上一个版本)
扩容、缩容： kubectl scale xxx


DaemonSet:
ikubernetes/filebeat:5.6.5-alpine
支持rollingUpdate和deleteUpdate, 仅支持maxUnavaliable方式(默认1)

JOB:
batch/v1 , Job
spec.parallelism 并发数, completions 总数
扩容：kubectl scale jobs/job-name --replicas=3
删除： spec.activeDeadlineSeconds 最大活动时间, backoffLimit 重试次数，默认6

CronJob：
batch/v1beta1, CronJob, spec.schedule
kubectl run crontabjob2 --schedule="*/1 * * * *" --restart=OnFailure --image=busybox -- /bin/sh -c "date; echo Hello from the Kubernetes cluster"
cocurrencyPolicy: 是否允许并行

PDB: pod distribution budget 
policy/v1beta1, PodDisruptionBudget

8.service和ingress
kube proxy请求代理方式：userspace, iptables, ipvs(默认)

kubectl expose xxx
kubectl get endpoints


会话粘性：session affinity 只能基于IP,NAT过来的无法区分
spec.sessionAffinity(None/ClientIP), sessionAffinityConfig(时长，默认10800秒,配合timeoutSeconds)

服务发现：coredns
zookeepr/etcd/dns
Eureka(Netflix), Consul(HashiCorp)

服务暴露：
service类型： spec.type  ClusterIP, NodePort, LoadBalancer, ExternalName(将外部服务映射到集群内)

Headless Service:没有clusterIP, nslookup会解析出所有endpoint地址，可用于外部服务发现
kubectl run cirros-$RANDOM --rm -it --image=cirros -- sh
nslookup headless-service


Ingress Controller:  实现方式nginx, Envoy, HaProxy, Traefik

9. 数据卷与持久化
emptyDir,hostPath,NFF, Gitrepo........； 特殊类型： Secret, ConfigMap
emptyDir: 跟随pod生命周期
gitRepo: (已废弃？)
hostPath:
Ceph RBD

PV/PVC, StorageClass
downwardAPI: 环境变量注入，存储卷式元数据注入 **？？

10. 配置 ConfigMap和Secret
通过命令行参数；通过环境变量(Environment)
configmap(cm): 键值对，文件（两级软连接，支持自动更新），目录，yaml(v1, ConfigMap, data)
kubectl create configmap cm-network --from-file=/root/ifcfg-ens37
configmap存储卷：（不支持自动更新）

secret: 4种资源类型 Opaque(base64, generic), kubernetes.io/service-account-token, 
kubectl create secret generic test-secret --from-literal=username='breeze',password='123456'
echo -n "xiahang" | base64

kubectl create secret generic test-secret --from-literal=username='breeze',password='123456'
加密：echo -n "xiahang" | base64
解密：echo xxx | base64 -d

tls：
(umask 077; openssl genrsa -out nginx.key 2048)
openssl req -new -x509 -key nginx.key -out nginx.crt -subj /c=CN/ST=Beijing/L=Beijing/O=DevOps/CN=jack.cn
kubectl create secret tls nginx-tls --key=./nginx.key --cert=./nginx.crt

secret存储卷
imagePullSecret对象：
kubectl create secret docker-registry local-registry --docker-username=xxx --docker-password=xxx --docker-email=xxx

11. statefulset


12. 认证、授权、准入控制
Authentication(鉴定用户)->Authorization(操作权限鉴定)->Admin Control(资源对象具体操作权限检查)
user account, service account -> 用户组 system:unauthenticated, system:authenticated, system:serviceaccounts, system.serviceaccounts:<namespace>

认证方式：
X509客户端证书认证()：/CN=linux/O=admin Common Name, Organization(用户，组)
Static Token File: 
webhook令牌：
匿名请求：system:anonymous

授权方式：
Node, ABAC(Attribute-based access control), RBAC(role-based), Webhook

准入控制器:
ServiceAccount, ...

kubectl create secretaccount xxx
(可以提前指定imagePullSecrets)

X509认证：
ssl/tls服务端认证： 客户端单向验证服务端； 双向认证
etcd集群内部通信： peer类型证书
etcd客户端与服务器： reset API, 2379,  双向认证
三大类客户端：
控制平面：kube-scheduler, kube-controller-manager
工作组节点：kubelet, kube-proxy  通过tls bootstraping自动生成
POD及其他：

kubeconfig: kubectl config view/set-cluster/set-context/use-context (默认context: kubernetes-admin@kubernetes)
(kubectl get pods --context=kubernetes-admin@kubernetes 临时指定context)
创建用户账号过程：
a. 生成私钥文件： (umask 077;openssl genrsa -out kube-user1.key 2048)
b.创建证书签署请求 
openssl req -new -key kube-user1.key -out kube-user1.csr -subj "/CN=kube-user1/O=kube-group"
c. 基于系统CA签署证书：
openssl x509 -req -in kube-user1.csr -CA /etc/kubernetes/pki/ca.crt  -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out kube-user1.crt -days 3650
d.验证 openssl x509 -in kube-user1.crt -text -noout
e. 生成kubeconfig配置文件
kubectl config set-credentials kube-user1 --embed-certs=true --client-certificate=./kube-user1.crt --client-key=./kube-user1.key 
kubectl config set-context kube-user1@kubernetes --cluster=kubernetes --user=kube-user1
kubectl config use-context kube-user1@kubernetes

11. statefulset

12. 认证、授权、准入控制
Authentication(鉴定用户)->Authorization(操作权限鉴定)->Admin Control(资源对象具体操作权限检查)
user account, service account -> 用户组 system:unauthenticated, system:authenticated, system:serviceaccounts, system.serviceaccounts:<namespace>

认证方式：
X509客户端证书认证()：/CN=linux/O=admin Common Name, Organization(用户，组)
Static Token File: 
webhook令牌：
匿名请求：system:anonymous

授权方式：
Node, ABAC(Attribute-based access control), RBAC(role-based), Webhook

准入控制器:
ServiceAccount, ...

kubectl create secretaccount xxx
(可以提前指定imagePullSecrets)

X509认证：
ssl/tls服务端认证： 客户端单向验证服务端； 双向认证
etcd集群内部通信： peer类型证书
etcd客户端与服务器： reset API, 2379,  双向认证
三大类客户端：
控制平面：kube-scheduler, kube-controller-manager
工作组节点：kubelet, kube-proxy  通过tls bootstraping自动生成
POD及其他：

kubeconfig: kubectl config view/set-cluster/set-context/use-context (默认context: kubernetes-admin@kubernetes)
(kubectl get pods --context=kubernetes-admin@kubernetes 临时指定context)
创建用户账号过程：
a. 生成私钥文件： (umask 077;openssl genrsa -out kube-user1.key 2048)
b.创建证书签署请求 
openssl req -new -key kube-user1.key -out kube-user1.csr -subj "/CN=kube-user1/O=kube-group"
c. 基于系统CA签署证书：
openssl x509 -req -in kube-user1.csr -CA /etc/kubernetes/pki/ca.crt  -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out kube-user1.crt -days 3650
d.验证 openssl x509 -in kube-user1.crt -text -noout
e. 生成kubeconfig配置文件
kubectl config set-credentials kube-user1 --embed-certs=true --client-certificate=./kube-user1.crt --client-key=./kube-user1.key 
kubectl config set-context kube-user1@kubernetes --cluster=kubernetes --user=kube-user1
kubectl config use-context kube-user1@kubernetes

kubectl config set-context kubernetes-admin@kubernetes


RBAC:
role/clusterrole, rolebinding/clusterrolebinding
kubectl create ns testing
修改当前namespace: kubectl config set-context --current --namespace=testing
(kubectl api-resources --namespaced=true)

role: namespace级别(无法配置pv,node,namespace等资源,所以需要clusterRole)
rules.apiGroups, resources, verbs(get,list,create,update,patch,watch,proxy,redirect,delete,deletecollection)

kubectl create role servie-admin --verb="*" --resources="services,services/*" -n testing (不能有空格)

kubectl create rolebinding admin-services --role=service-admin --user=kube-user1 -n testing

一般clusterRole/ClusterRolebinding
kubectl describe clusterrole/system:discovery: nonResourceURLs
kubectl get clusterrolebinding/system:discovery -o yaml

聚合型 ClusterRole(匹配某些clusterrole)
metadata.aggregationRule.clusterRoleSelectors.matchLabels
样例：kubectl get clusterrole/admin -o yaml

内建的ClusterRole(非system:开头): cluster-admin 

利用系统内置的快速配置权限;rolebinding绑定到clusterrole上，可以限定到namespace级别权限
kubectl create rolebiding dev-admin --clusterrole=admin --user=kube-user1 -n testing

Dashboard部署验证：(1.7以后版本必须配https才能远程访问)
(umask 077; openssl genrsa -out dashboard.key 2048)
openssl req -new -key dashboard.key -out dashboard.csr -subj "/O=iKubernetes/CN=dashboard"
openssl x509 -req -in dashboard.csr -CA /etc/kubernetes/cert/ca.pem -CAkey /etc/kubernetes/cert/ca-key.pem -CAcreateserial  -out dashboard.crt -days 3650
kubectl create secret generic kubernetes-dashboard-certs -n kube-system --from-file=dashboard.crt=./dashboard.crt --from-file=dashboard.key=./dashboard.key -n kube-system
kubectl apply -f dashboard.yaml
配置token认证：
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
ADMIN_SECRET=$(kubectl -n kube-system get secret | awk '/^dashboard-admin/{print $1}')
kubectl describe secrets $ADMIN_SECRET -n kube-system kube-system
获取到的token即可登录dashboard

配置kubeconfig认证：
a.初始化集群信息 kubectl config set-cluster kubernetes --embed-certs=true --server="https://192.168.152.128:6443" \
--certificate-authority=/etc/kubernetes/pki/ca.crt --kubeconfig=./dashboard-admin.kubeconfig
b.获取dashboard-admin的token： 
ADMIN_SECRET=$(kubectl -n kube-system get secret | awk '/^dashboard-admin/{print $1}')
ADMIN_TOKEN=$(kubectl  -n kube-system get secret $ADMIN_SECRET -o jsonpath={.data.token}|base64 -d)
kubectl config set-credentials dashboard-admin --token=$(ADMIN_TOKEN) --kubeconfig=./dashboard-admin.kubeconfig
c. 定义context:kubectl config set-context dashboard-admin --cluster=kubernetes --user=dashboard-admin --kubeconfig=./dashboard-admin.kubeconfig
d.指定context: kubectl config use-context dashboard-admin --kubeconfig=./dashboard-admin.kubeconfig


准入控制器：
CPU内存： LimitRange, LimitRanger
kind: LimitRange, spec.limits
创建pod: kubectl run limit-pod1 --image=csuxh/jackhttpd:v1.2 --restart=Never
[root@jack-master security]# kubectl run limit-pod1 --image=csuxh/jackhttpd:v1.2 --restart=Never --requests='cpu=400m'
Error from server (Forbidden): pods "limit-pod1" is forbidden: minimum cpu usage per Container is 500m, but request is 400m.
ResourceQuota资源： ResourceQuota, spec.hard
kubectl describe quota/quota-example -n testing
kubectl run limit-pod2 --image=csuxh/jackhttpd:v1.2 --replicas=1  --requests='cpu=400m,memory=256Mi' --limits='cpu=500m,memory=500Mi' -n testing
PodSecurityPolicy(PSP):集群级别准入控制器
kubectl explain psp
使用步骤：
a.创建psp
b.创建clusterrole和clusterrolebinding
c.启用apiserver的psp准入控制器： --enable-admission-plugin后添加PodSecurityPolicy
d.验证




13.网络
pod网络实现方式：
伪网络接口：虚拟网桥, 多路复用, 硬件交换
CNI规范、CNI插件：容器管理系统<->网络插件,通过json通信
常用CNI插件：flannel,Calico,kube-router,Weave...
两类问题：不同容器ip重复，路由

Flannel：不支持网络策略,可以配合calico提供网络策略(通过canal部署)
后端：VxLAN(可以配置directrouting),  host-gw, UDP
ip route show

配置在configmap里：cm/kube-flannel-cfg

NetworkPolicy
curl https://docs.projectcalico.org/v3.8/manifests/canal.yaml -O
https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/flannel

Calico



14.POD资源调度
Predicate(预选)->Priority(优先级)->Select
节点亲和调度(spec.affinity.nodeAffinity)：required(硬亲和), preferred(软亲和)
  标签选择器：In,NotIn,Exists,DoesNotExist,Lt,Gt
  kubectl explain pod.spec.affinity.nodeAffinity
pod资源亲和调度： 位置，
kubectl explain pod.spec.affinity.podAffinity, podAntiAffinity
taints & tolerations
master自带taint no schedule, 系统级pod自带tolerations: kubectl describe pod/kube-flannel-ds-amd64-pzmmn -n kube-system
管理taint:
添加 kubectl taint nodes node-name key=value:effect
删除 kubectl taint nodes node-name key=value:effect-
删除所有 kubectl taint nodes node-name key-
优选级和抢占式调度

15.系统扩展
CRD:CustomResourceDefinitions
kubectl explain CustomResourceDefinition.spec.validation
子资源、状态：spec.subresources.status, spec.subresources.scale(支持伸缩)
categories: 资源类别 spec.names.categories (kubectl get all)
多版本支持：spec.version -> spec.versions

自定义控制器：<-> 系统内建控制器Controller Manager
三种模式：
 声明式API: kubectl apply
 异步：客户端请求于API server存储完成之后即返回，无需等待执行结果
 水平式处理(level-based)：仅处理最新的变动
两个组件：
Informer/SharedInformer：Listwatcher, ResourceEventHandler, ResyncPeriod
Workqueue: 后端处理

Kubebuilder, Operator SDK, Metacontoller
https://github.com/nikhita/custom-database-controller

自定义API Server: 先需要将自定义API Server 以Pod 形式运行于集群之上并为其创建Service 对象， 而后创建一个专用的APIService 对象与主API Server 完成聚合
kube-aggregator
kubectl get apiservice



集群高可用
etcd: raft选举
Controller Manager: 分布式锁机制，各实例抢占endpoint资源锁(k8s支持Endpoints和ConfigMap两种类型资源锁)
kubectl get endpoints/kube-scheduler -n kube-system -o yaml (annotations control-plane.alpha.kubernetes.io/leader: holderIdentity和renewTime )



16.资源指标及HPA控制器
集群指标,容器指标,应用程序指标
cAdvisor, Heapster(InfluxDB, Grafana展示)
metrics-server(资源指标API)：1.7以后;核心流水线、监控流水线;不存储历史数据
k8s-prometheus-adapter:自定义指标API

kubectl apply -f 1.8+/
kubectl api-versions | grep metrics
访问方式：
a.通过 kube-apiserver 或 kubectl proxy 访问：
https://192.168.152.128:6443/apis/metrics.k8s.io/v1beta1/nodes
https://172.27.129.105:6443/apis/metrics.k8s.io/v1beta1/nodes/
https://172.27.129.105:6443/apis/metrics.k8s.io/v1beta1/pods
https://172.27.129.105:6443/apis/metrics.k8s.io/v1beta1/namespace//pods/
b.直接使用 kubectl 命令访问
kubectl get --raw "/apis/metrics.k8s.io/v1beta1" | jq .
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
kubectl get --raw apis/metrics.k8s.io/v1beta1/pods
kubectl get --raw apis/metrics.k8s.io/v1beta1/nodes/
kubectl get --raw apis/metrics.k8s.io/v1beta1/namespace//pods/

Top命令： kubectl top node/


Prometheus:
通过apiserver发现资源
prometheus.io/scrape
prometheus.io/path
prometheus.io/port
组件：
kube-state-metrics
exporter、Node Exporter
Alertmanager:
TSDB: time series database -> PromQL
自定义指标适配器：k8s-prometheus-adapter

自动伸缩
HPA: Horizonal Pod Autoscaler HPA(v2)
CA: cluster autoscaler
VPA: Vertical Pod Autoscaler
AR：Addon Resizer







rancher
https://k3s.io


kubectl get pod -o wide | grep Completed | awk '{print $1}' | xargs kubectl delete pod

教程：
https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-service-loadbalancer-em-
命令：https://kubernetes.io/docs/reference/kubectl/cheatsheet/
指南：https://kubernetes.feisky.xyz/he-xin-yuan-li/index
