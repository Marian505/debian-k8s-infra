kubectl port-forward svc/kibana 5601:5601 -n dev --address 0.0.0.0

kubectl get all -A

kubectl delete all --all --all-namespaces


kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml


kubectl patch svc kong-kong-proxy -n kong -p '{"spec":{"externalIPs":["192.168.100.51"]}}'
kubectl patch svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -p '{"spec":{"externalIPs":["192.168.100.51"]}}'
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"externalIPs":["192.168.100.51"]}}'

helmfile -e development apply
helmfile -e development destroy

kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o yaml


helm install cilium cilium/cilium --namespace kube-system --set operator.replicas=1



cilium:

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin && rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium version --client


delete node:
kubectl drain debian --ignore-daemonsets --delete-emptydir-data --force
kubectl delete node debian
kubeadm reset --force
or
systemctl stop kubelet containerd docker
rm -rf /var/lib/kubelet/* /etc/kubernetes /var/lib/etcd /var/lib/cni /etc/cni
ip link delete cni0 | true
ip link delete flannel.1 | true
systemctl restart containerd docker kubelet


KUBE_EDITOR=nano kubectl edit configmap kube-proxy -n kube-system