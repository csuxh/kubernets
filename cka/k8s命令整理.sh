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


rancher
https://k3s.io


kubectl get pod -o wide | grep Completed | awk '{print $1}' | xargs kubectl delete pod
