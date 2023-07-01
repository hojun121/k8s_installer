#/bin/bash
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl bridge-utils -y
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install kubeadm=1.21.0-00 kubelet=1.21.0-00 kubectl=1.21.0-00 containerd=1.3.3-0ubuntu2 docker.io=19.03.8-0ubuntu1 -y
sudo apt-mark hold kubeadm kubelet kubectl docker
sudo systemctl restart docker
sudo systemctl restart kubelet
sudo systemctl enable docker.service
