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
存活性探测： livenessProbe  readinessProbe
ExecAction, TCPSocketAction, HTTPGetAction
(restartPolicy: Always/OnFailure/NEVER)




 secret:
kubectl create secret generic test-secret --from-literal=username='breeze',password='123456'

echo -n "xiahang" | base64
