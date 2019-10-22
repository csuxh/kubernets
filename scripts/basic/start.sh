for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler   kube-proxy  kubelet docker flanneld   ; 
do systemctl restart   $SERVICES; 
systemctl enable $SERVICES; 
systemctl status $SERVICES; 
done;
