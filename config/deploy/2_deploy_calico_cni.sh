#/bin/bash
sudo curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
sudo sed -i -e 's?192.168.0.0/16?10.10.0.0/16?g' calico.yaml
kubectl apply -f calico.yaml
