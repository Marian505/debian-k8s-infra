# usefull commands
```bash
kubectl get all -A
kubectl delete all --all --all-namespaces
kubectl port-forward svc/kibana 5601:5601 -n dev --address 0.0.0.0

watch kubectl get all -A

sudo systemctl daemon-reload
sudo systemctl restart kubelet containerd
sudo systemctl status kubelet containerd

journalctl -u kubelet -f
ps aux | grep kubelet
sudo systemctl cat kubelet.service

kubectl rollout restart deployment coredns -n kube-system

helmfile apply
helmfile sync
helmfile destroy
or 
helmfile -e development apply
helmfile -e development destroy

kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o yaml

KUBE_EDITOR=nano kubectl edit configmap kube-proxy -n kube-system

kubectl delete pod fastapi-895fb884d-5g7cl -n dev --force --grace-period=0

```

## others
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml


kubectl patch svc kong-kong-proxy -n kong -p '{"spec":{"externalIPs":["192.168.100.51"]}}'
kubectl patch svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -p '{"spec":{"externalIPs":["192.168.100.51"]}}'
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"externalIPs":["192.168.100.51"]}}'

cilium uninstall
sudo rm -f /etc/cni/net.d/*cilium*.conf /etc/cni/net.d/*cilium*.conflist
sudo rm -f /usr/lib/cni/bin/cilium-cni
```


# Kubernetes install

Some of versions are hardcoced adapt script to current latest or needed version.

## sources:
https://www.bentasker.co.uk/posts/documentation/linux/building-a-k8s-cluster-on-debian-12-1-bookworm.html </br>
https://kubernetes.io/docs/setup/production-environment/container-runtimes </br>
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm

## setup linux
```bash
sudo swapoff -a
sudo nano /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

## install containerd
```bash
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd # if does not exist
containerd config default | sudo tee /etc/containerd/config.toml

sudo nano /etc/containerd/config.toml
```

### Edit /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options] </br>
  SystemdCgroup = true

bin_dir = "/opt/cni/bin" # importatnt step, set path to your cni binaries

"registry.k8s.io/pause:3.8" -> "registry.k8s.io/pause:3.10.1" # not necessary and version can change

```bash
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl status containerd
```

## install kubelet kubeadm kubectl
```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
```

## init cluster
Calium default CIDR 10.244.0.0/16 
Calico default CIDR 192.168.0.0/16
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU,Mem
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///run/containerd/containerd.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane- # required for single node
kubectl get nodes # not ready until install CNI
```

## Verify RBAC/DNS
kubectl get clusterrolebinding | grep coredns  # Exists!
kubectl auth can-i list services --as=system:serviceaccount:kube-system:coredns  # yes
kubectl rollout status deployment/coredns -n kube-system  # Running

## instal Calium
```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.18.4 \
  --set kubeProxyReplacement=true \ # importatnt step
  --set ipam.operator.clusterPoolIPv4PodCIDRList={10.244.0.0/16}
cilium status --wait

kubectl run test --image=nginx # for test only
cilium connectivity test # takes 5-8 minutes
```

## merge/manage kube config
```bash
cat ~/.kube/config # to your local machine and save as xxx.yml
export KUBECONFIG=~/.kube/local.yml:~/.kube/dev.yml
kubectl config view --flatten > ~/.kube/config
unset KUBECONFIG

kubectl config get-contexts
​kubectl config current-context
​kubectl config use-context <context-name>
kubectl config set-context <ctx> --namespace=dev
```
Or
```bash
kubectl --kubeconfig ~/.kube/dev.yml get pods
```

## delete node
```bash
kubectl drain k8s --ignore-daemonsets --delete-emptydir-data --force
kubectl delete node k8s
kubeadm reset  # or kubeadm reset --force
```

## git runner 
sudo ./svc.sh install
sudo ./svc.sh start

## Metallb
Manual setting. It does not work over helm file

kubectl get cm kube-proxy -n kube-system -o yaml | sed -e 's/strictARP: false/strictARP: true/' | kubectl diff -f - -n kube-system
kubectl get cm kube-proxy -n kube-system -o yaml | sed -e 's/strictARP: false/strictARP: true/' | kubectl apply -f - -n kube-system
kubectl rollout restart ds kube-proxy -n kube-system

helm repo add metallb https://metallb.github.io/metallb
helm repo update
helmfile sync

does not fork from helmfile:
manifests:
  - path: metallb/metallb-config.yaml

kubectl apply -f metallb/metallb-config.yaml -n metallb-system


export KUBE_EDITOR=nano

## debug
kubectl get events -n metallb-system --sort-by=.metadata.creationTimestamp | grep speaker
kubectl logs metallb-speaker-qljm5 -n metallb-system -c speaker --previous 
kubectl logs metallb-speaker-qljm5 -n metallb-system --all-containers
kubectl rollout restart ds metallb-speaker -n metallb-system

kubectl delete pod cilium-envoy-j6nlf -n kube-system --grace-period=0 --force
kubectl describe node k8s

kubectl get ciliumloadbalancerippool homelab-pool -o yaml 

kubectl delete svc ai-agent fastapi langgraph-cloud-studio -n dev
kubectl expose deployment ai-agent --type=LoadBalancer -n dev --port=8000

kubectl run curl-test --rm -i --tty --image=curlimages/curl --restart=Never -n dev -- /bin/sh
curl http://service/fastapi.dev.svc.cluster.local:80
curl http://fastapi.dev.svc.cluster.local:8000/docs

kubectl exec -it ai-agent-f75f75c64-sthvg -n dev -- sh