kubectl port-forward svc/kibana 5601:5601 -n dev --address 0.0.0.0

kubectl get all -A

kubectl delete all --all --all-namespaces

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

kubectl patch svc kong-kong-proxy -n kong -p '{"spec":{"externalIPs":["192.168.100.51"]}}'