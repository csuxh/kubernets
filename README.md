# kubernets
Kubeadm方式安装
1. hostnamectl set-hostname jack-master --static
master：
vim /etc/sysconfig/kubelet命令修改kubelet配置，修改内容为
KUBELET_EXTRA_ARGS="--fail-swap-on=false

kubeadm init --kubernetes-version=1.14.2 \
--apiserver-advertise-address=192.168.152.128 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=10.244.0.0/16 \
--ignore-preflight-errors=NumCPU --ignore-preflight-errors=Swap

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml


swap:
kubeadm join 192.168.152.129:6443 --token 9sdqn7.ytpe63y8ddqkkm18     --discovery-token-ca-cert-hash sha256:f32d01cd32e9b617164c7ac0439d8008e989b5301f358be90b11657d0e410bf4  --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Swap
