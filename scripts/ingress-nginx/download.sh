for file in  namespace.yaml configmap.yaml rbac.yaml with-rbac.yaml ; do curl -O https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/${file};done
