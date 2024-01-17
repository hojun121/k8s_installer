#/bin/bash
sudo kubeadm reset --force
sudo systemctl stop kubelet
sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get purge kubeadm kubelet kubectl --auto-remove -y
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/cni/
sudo rm -rf /etc/kubernetes
sudo rm -rf $HOME/.kube
