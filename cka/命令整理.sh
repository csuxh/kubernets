1. master参与调度
kubectl taint node k8s-master node-role.kubernetes.io/master-

kubectl run jackhttpd-deploy --image=csuxh/jackhttpd:v1.0 --replicas=2

kubectl expose deployment jackhttpd-deploy --type=NodePort/ClusterIP --name=httpd-service --port=80 --target-port=9999


2. secret:
kubectl create secret generic test-secret --from-literal=username='breeze',password='123456'

echo -n "xiahang" | base64

3. node selector
kubectl label nodes jack-node type=mysql-server
