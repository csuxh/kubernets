kubectl run --image=busybox my-deploy1 -o yaml --dry-run > my-deploy.yaml

kubectl get service/my-nginx -o=yaml --export > new.yaml

kubectl explain pod.spec.affinity

kubectl scale deployment dp-nginx --replicas=2

