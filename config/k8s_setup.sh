sudo echo "sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo swapoff -a
sudo sed -i '/swap/s/&/#/' /etc/fstab
sudo ufw disable
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg  https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 kubectl=1.28.2-00
sudo apt-mark hold kubelet kubeadm kubectl
sudo cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee -a /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
sudo echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.26/xUbuntu_20.04/ /" | sudo tee -a /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.26.list
sudo curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.26/xUbuntu_20.04/Release.key | sudo apt-key add -
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install cri-o cri-o-runc -y
sudo systemctl daemon-reload
sudo systemctl enable crio --now" | sudo tee -a /home/install.sh && sudo chmod +x /home/install.sh && sudo sh /home/install.sh
