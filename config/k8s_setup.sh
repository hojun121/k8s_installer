#/bin/bash
sudo swapoff -a && sed -i '/swap/s/&/#/' /etc/fstab
sudo ufw disable
sudo apt-get update
# CRI: Docker Containerd Package Configuration
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl bridge-utils gnupg lsb-release docker-ce docker-ce-cli containerd.io bash-completion
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl start docker
sudo sed -i -e '/disabled_plugins/ s/^/#/' /etc/containerd/config.toml
sudo systemctl restart containerd
# Kubernetes Package Configuration
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install kubeadm=1.27.4-00 kubelet=1.27.4-00 kubectl=1.27.4-00 -y
sudo apt-mark hold kubeadm kubelet kubectl docker
sudo systemctl enable kubelet
sudo systemctl restart kubelet
