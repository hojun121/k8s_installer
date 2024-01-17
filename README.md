# k8s auto installer

## 모듈 소개
* N개의 Instance 들을 kubernetes cluster 환경으로 자동 구축해주는 모듈이다.
  * 수동 설치를 원할 경우, 아래 [Kubernetes v1.28.2 수동 설치 가이드(Ubuntu 20.04)](#kubernete-수동-설치-가이드) 항목 참고
* golang(v1.20.3) 으로 개발되었으며 모든 작업(Go-routine 기반)은 병렬적으로 수행된다.
* 본 모듈은 Linux/Amd64 환경에서 Test 되었으며, 실행 가능한 바이너리 파일(kubeins)과 Config 디렉토리만 있으면 정상 동작한다.
* On-Premise, AWS, Naver Cloud 에서 정상 동작 확인

## 사용법
```
mkdir ~/binary
cd ~/binary
cp -r ~/k8s-installer/config ./
cp ~/k8s-installer/kubeins ./
kubeins -h
```

## 구성 요소 상세 설명

```
.
├── config
│   ├── config.yaml
│   ├── deploy
│   │   ├── 1_kubectl_setup.sh
│   │   ├── 2_deploy_calico_cni.sh
│   ├── k8s_remove.sh
│   └── k8s_setup.sh
└── kubeins
```

* config 디렉토리
  * config.yaml
    * 인스턴스 정보, k8s 설정 정보 파일
  * k8s_setup.sh
    * install 시 모든 노드에 실행되는 스크립트 파일
    * k8s 구성에 필요한 패키지 설치 명령어들로 구성
    * 자유롭게 수정 가능
  * k8s_remove.sh
    * remove 시 모든 노드에 실행되는 스크립트 파일
    * cluster reset 및 kubeadm, kubectl, kubelet, docker 바이너리 & 설정 파일들 삭제
    * 자유롭게 수정 가능
  * deploy
    * kubectl이 설정된 노드(master1)에서 실행되는 스크립트 파일들이 들어있는 디렉토리
    * 파일들은 1_{{ 파일 이름 }}, 2_ {{ 파일 이름 }}, 3_{{ 파일 이름 }} 으로 파일 이름 앞에 "숫자_"를 prefix로 붙임
    * 새로운 파일을 추가 하고 싶다면 4_{{ 파일 이름 }} 으로 생성
* kubeins 바이너리
  * Linux/Amd64에서 동작하는 바이너리 파일
    * kubeins -h => 옵션 살펴보기
    * kubeins -f {{ Config File Directory Path }} => 지정한 Config File Directory 를 읽어 동작 (Default: "./config")
    * kubeins -m {{ kubeins Execute Mode }} => kubeins 실행 모드로 install 및 remove 지원 (Default: "install")
    * kubeins -u {{ UserName of Instances }} => 인스턴스 접속에 필요한 계정 정보 (Default: "ubuntu")
    * kubeins -i {{ PemKey Path }} => 인스턴스 접속에 필요한 Pem Key 파일 경로 (Default: "")
    * kubeins -p {{ Password }} => 인스턴스 접속에 필요한 Password (Default: "")
  * 동작 예시
    ```
    # 아래 명령어 실행 시킬 경우, "./config" 디렉토리를 읽어 "ubuntu" 계정으로 "install" 모드로 동작
    kubeins 
    ```
    ```
    # 아래 명령어 실행 시킬 경우, "/etc/config" 디렉토리를 읽어 "hoya" 계정 및 "/etc/mypem.key" 으로 "remove" 모드로 동작
    kubeins -u hoya -f /etc/myconfig -m remove -i /etc/mypem.key
    ```
## 동작 과정
* Install Mode (Step by Step으로 각 Task를 실행하며 오류 발생 시 Stop / 실패 Instance 정보 및 error log 출력)
  * config 설정 파일 Load
  * (1) 모든 노드에 k8s_setup.sh 복사 (sshpass scp 활용)
  * (2) 모든 노드에 k8s_setup.sh 실행 (sshpass ssh 활용)
  * (3) master 노드 중 1개의 노드에 kubeadm init 수행 및 join 명령어 파싱
  * (4) 나머지 노드에게 kubeadm join 수행
  * (5) Master 노드 중 1개의 노드에 config/deploy 디렉토리 안의 스크립트 파일 실행
* Remove Mode (Step by Step으로 각 Task를 실행하며 오류 발생 시 Stop / 실패 Instance 정보 및 error log 출력)
  * config 설정 파일 Load
  * (1) 모든 노드에 k8s_remove.sh 복사 (sshpass scp 활용)
  * (2) 모든 노드에 k8s_remove.sh 실행 (sshpass ssh 활용)

<br>

# Kubernete 수동 설치 가이드

**[중요] Kubernetes 설치 및 구성에 대한 이해(전체 청사진)는 [본 링크](#kubernetes-동작-및-설치-과정-전체-청사진) 참조!** 

## 1. Kubernetes 구성 요소 버전

- Host OS: Ubuntu 20.04
- CRI: Crio v1.26.4
- CNI: Calico v3.26.1
- Kubectl: v1.28.2
- kubeadm: v1.28.2
- kubelet: v1.28.2

## 2.  Virtual Machine 정보

- Node Spec 정보
    - Master Spec (Naver Cloud XEN Server)
        - 마스터 노드 3대
            - 8 Core / 16 Ram / SSD 50 GB
    - Worker Spec (Naver Cloud XEN Server)
        - 서비스 전용 노드 2대
            - 16 Core / 32 Ram / SSD 50 GB
        - DB 전용 노드 2대
            - 8 Core / 64 Ram / SSD 50 GB
- Kubernetes Node를 위한 필수 방화벽 정보

    ![Untitled](https://github.com/hojun121/k8s_installer/assets/107022839/1f6227ec-3194-4d24-8288-595e561d86d2)

- Kuberentes CNI를 위한 필수 방화벽 정보
    - [CNI(Calico Network) 필요 Port 정보 링크](https://projectcalico.docs.tigera.io/getting-started/kubernetes/requirements)
    
    ![Untitled 1](https://github.com/hojun121/k8s_installer/assets/107022839/75050a96-50b1-4640-99f4-e13a54329a1e)
    

## 3. Master, Worker 모두 적용해야하는 명령어들

- 모든 kubernetes 노드에 수행해야함
    - All-In-One Script 실행 (각 명령어의 상세 설명은 아래 참조)
        
        ```bash
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
        ```
        
- (1/3) 사전 구성 작업 수행
    - 구성 필수 패키지 설치
    
    ```bash
    sudo apt-get update -y && sudo apt-get install -y apt-transport-https ca-certificates curl
    ```
    
    - Swap 메모리 비활성화 (k8s는 Swap 메모리가 켜져있는 경우 설치 진행 불가)
    
    ```bash
    sudo swapoff -a && sudo sed -i '/swap/s/&/#/' /etc/fstab
    ```
    
    - 방화벽 비활성화
    
    ```bash
    sudo ufw disable
    ```
    
- (2/3) Kubernetes 운영 및 설치 도구 패키지 설치
    - Ubuntu 20.04의 경우 **`/etc/apt/keyrings`** 디렉토리가 없음으로 생성 필요
    - apt repo 업데이트 및 설치 후, 패키지 버전 고정
    - apt 패키지 버전 확인 명령어: **`apt list -a kubeadm(or kubectl or kubelet)`**
    
    ```bash
    sudo mkdir -p /etc/apt/keyrings
    
    sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg  https://dl.k8s.io/apt/doc/apt-key.gpg
    
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    
    sudo apt-get update -y
    sudo apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 kubectl=1.28.2-00
    sudo apt-mark hold kubelet kubeadm kubectl
    ```
    
- (3/3) CRI(Container Runtime Interface) Cri-O 설치
    - 사전 구성 수행
        - 부팅 시 모듈 로드를 위해 .conf 파일 생성
    
    ```bash
    sudo cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
    overlay
    br_netfilter
    EOF
    
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```
    
    - 요구되는 sysctl 파라미터 설정(재부팅 시에도 유지됨)
    
    ```bash
    sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.ipv4.ip_forward                 = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    EOF
    sudo sysctl --system
    ```
    
    - Crio-O 설치
        - sock 위치는 **`/var/run/crio/crio.sock`**
        - kubeadm init 명령어 수행 시 필수로 지정해야함
    
    ```bash
    sudo echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee -a /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
    sudo echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.26/xUbuntu_20.04/ /" | sudo tee -a /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.26.list
    
    sudo curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.26/xUbuntu_20.04/Release.key | sudo apt-key add -
    sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | sudo apt-key add -
    
    sudo apt-get update -y
    
    sudo apt-get install cri-o cri-o-runc -y
    
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now
    ```
    

## 4. Kubernetes Clustering을 위한 적용 명령어

- **[중요] 마스터 노드(여러 개일 경우, 원하는 한 곳에서)**에서 명령어 수행
    - 단일 Master 구성일 경우, 아래 명령어 수행
        
        ```bash
        sudo kubeadm init --kubernetes-version=v1.28.2 --pod-network-cidr=10.10.0.0/16
        ```
        
    - Master HA 구성일 경우, 아래 명령어 수행
        - Master HA Endpoint 역할을 담당하는 LB 선 구성필요
            - Naver Cloud Network Proxy Loadbalancer (6443 listen) 생성
                - Target Group은 각 Master tcp 6443
            - Network Proxy Loadbalancer DNS 주소를 아래 **`--control-plane-endpoint`** 에 입력
        
        ```bash
        sudo kubeadm init --kubernetes-version=v1.28.2 --pod-network-cidr=10.10.0.0/16 --control-plane-endpoint=prod-nlb-silver-private-22196149-5220ac6b044e.kr.lb.naverncp.com --upload-certs
        ```
        
    
    ![Untitled 2](https://github.com/hojun121/k8s_installer/assets/107022839/6ca36939-5405-4ba0-9782-2da3612dc59d)

    
- **[중요] 명령어를 잘못입력하였거나 설정이 꼬였을 때, kubeadm init 명령어를 재입력하면 에러 발생. 그럴 경우 초기화 필요! `kubeadm reset` 입력 후 y enter**
- kubeadm init 명령어는 master component 구성 설정으로 다음 과정들이 **자동 수행**됨
    - CRI Runtime Sock 설정 및 Pod Network 대역 설정
        - **[중요] Kubernetes Pod Network 대역 설정!**
    - /etc/kubernetes/manifests에 yaml 파일 다운로드 수행
        - kubelet이 해당 yaml Pod 생성 (static pod)
        - etcd, kube-apiserver, kube-controller-manager, kube-scheduler
        - **[중요] Kubernetes 주요 Control Plane Pod 기동!**
    - TLS 관련 설정 및 admin.conf 파일 생성(kubeconfig)
        - **[중요] API Server와 통신할 수 있도록 인증서 생성!**
    - 위 과정이 끝나면 Kubeadm이 API Server와 통신하며 아래 과정 수행
        - Default Namespace 생성 (kube-system)
        - Admin RBAC(Role Base Access Control) 생성
        - **[중요] CoreDNS 및 kube-proxy Pod 배포**
- Master 노드 initialization이 끝나면 아래 화면처럼 보임
    
    ![Untitled 3](https://github.com/hojun121/k8s_installer/assets/107022839/1c18309e-2b55-4378-a1e6-218b0b3f7aa0)
    
    - **[중요] Master HA 구성이라면 다른 마스터들에게 <Master Clustering Join > 명령어 수행**
        - **[중요] Master Clustering 명령어는 노드별 순차적으로 수행 권장! 병렬적으로 수행할 경우, Clustering 장애 발생 가능성 존재**
        
        ```bash
        kubeadm join prod-nlb-silver-private-22196149-5220ac6b044e.kr.lb.naverncp.com:6443 --token {{ HASH }} \
                --discovery-token-ca-cert-hash {{ HASH }} \
                --control-plane --certificate-key {{ HASH }}
        ```
        
    - **[중요] 워커 노드들는 < Worker Clustering Join > 명령어 수행**
        - 병렬적으로 Clustering join 명령어 날려도 무방
        
        ```bash
        kubeadm join prod-nlb-silver-private-22196149-5220ac6b044e.kr.lb.naverncp.com:6443 --token {{ HASH }} \
                --discovery-token-ca-cert-hash {{ HASH }}
        ```
        
- 위 과정까지 모두 정상적으로 완료되었다면 Clustering 단계는 끝남!

## 5. Kubectl 도구 설정

- kubectl 이란?
    - Kubernetes Master API Server 와 통신하며 사용자 명령어를 지원하는 support tool
    - **[중요] kubernetes의 kubeconfig 파일을 Load하여 API Server와 HTTPS 통신 수행**
    - kubectl은 Master API Server와 통신만 되는 곳이라면 어디든 운영 가능
        - Local PC 또는 Bastion Server 등등
            - From [[ Local PC (kubectl) ]] to k8s
            - From [[ Local Bastion Server (kubectl) ]] to k8s
- kubeconfig 란?
    - k8s apiserver 주소 정보 및 인증서가 담긴 파일이며 일반적으로 "kubeconfig" 라고 부름
    - k8s 처음 설치하면 /etc/kubernetes 경로에 admin.conf로 존재 (**`/etc/kubernetes/admin.conf`)**
    - kubectl 은 kubeconfig 파일을 읽어서 apiserver와 통신
        - kubectl이 kubeconfig를 잘 load했는지 확인하는 방법은 아래 2가지로 확인 가능
    
    ```bash
    ===== kubectl 에 kubeconfig mapping 이 안되었을 때 ====
    
    $ kubectl config view
    
    apiVersion: v1
    clusters: null
    contexts: null
    current-context: ""
    kind: Config
    preferences: {}
    users: null
    ```
    
    ```bash
    ===== kubectl 에 kubeconfig mapping 이 안되었을 때 ====
    
    $ kubectl get nodes
    
    E0117 09:48:44.056346  135880 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
    E0117 09:48:44.056938  135880 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
    E0117 09:48:44.059054  135880 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
    E0117 09:48:44.059947  135880 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
    E0117 09:48:44.061658  135880 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
    The connection to the server localhost:8080 was refused - did you specify the right host or port
    ```
    
- kubectl이 kubeconfig 파일을 바라보도록 설정하는 방법 2가지 (둘 중 택 1가지)
    - (1) $HOME/.kube 디렉토리 생성 및 인증서 배치 (일반적으로 활용하는 방법)
        - $HOME/.kube 디렉토리 생성 후, kubeconfig 파일을 "config" 라는 이름으로 저장
        - kubectl 은 default로 $HOME/.kube/config 파일을 읽도록 되어있음
            
            ```bash
            mkdir -p $HOME/.kube
            ```
            
            ```bash
            cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
            ```
            
            ```bash
            chown $(id -u):$(id -g) $HOME/.kube/config
            ```
            
    - (2) KUBECONFIG 환경 변수 지정
        - kubectl 은 KUBECONFIG 환경 변수를 읽어서 파일을 가져오도록 되어있음
            
            ```bash
            export KUBECONFIG=/etc/kubernetes/admin.conf
            ```
            
    - **[중요] kubeconfig 파일은 master 노드들에만 존재!**
        - master 노드와 worker 노드에서 ls /etc/kubernetes 입력하여 확인 권장
    - kubectl이 kubeconfig를 잘 load했는지 다시 확인
        
        ```bash
        ===== kubectl 에 kubeconfig mapping 이 되었을 때 ====
        
        $ kubectl config view
        
        apiVersion: v1
        clusters:
        - cluster:
            certificate-authority-data: DATA+OMITTED
            server: https://prod-nlb-silver-private-22196149-5220ac6b044e.kr.lb.naverncp.com:6443
          name: kubernetes
        contexts:
        - context:
            cluster: kubernetes
            user: kubernetes-admin
          name: kubernetes-admin@kubernetes
        current-context: kubernetes-admin@kubernetes
        kind: Config
        preferences: {}
        users:
        - name: kubernetes-admin
          user:
            client-certificate-data: DATA+OMITTED
            client-key-data: DATA+OMITTED
        ```
        
        ```bash
        ===== kubectl 에 kubeconfig mapping 이 되었을 때 ====
        
        $ kubectl get nodes
        
        NAME                          STATUS   ROLES           AGE   VERSION
        prod-silver-master-1-kr1      Ready    control-plane   45m   v1.28.2
        prod-silver-master-2-kr2      Ready    control-plane   43m   v1.28.2
        prod-silver-master-3-kr1      Ready    control-plane   44m   v1.28.2
        prod-silver-worker-1-kr1      Ready    <none>          23m   v1.28.2
        prod-silver-worker-2-kr2      Ready    <none>          23m   v1.28.2
        prod-silver-worker-db-1-kr1   Ready    <none>          23m   v1.28.2
        prod-silver-worker-db-2-kr2   Ready    <none>          23m   v1.28.2
        ```
        
    - **[중요] 만약 x509 에러(인증서 에러)가 발생했다면, kubectl이 (구)kubeconfig을 읽어들인것**
        - /etc/kubernetes/admin.conf 를 토대로 위 설정 1번째 또는 2번째를 다시 수행합시다.

## 6. Kubectl을 통한 CNI(Container Network Interface) 배포

- kubernetes는 Default CNI 설정이 안되어 있음
    - Networking을 담당하는 coredns가 ContainerCreating 상태로 유지되는 중
    
    ```bash
    ==== CNI 배포하기 전 Kubernetes Core DNS 상태 ====
    
    $ kubectl get pod --namespace kube-system
    
    NAME                                               READY   STATUS              RESTARTS      AGE
    coredns-5dd5756b68-ctf9v                           0/1     ContainerCreating   0             61m
    coredns-5dd5756b68-xd48h                           0/1     ContainerCreating   0             61m
    etcd-prod-silver-master-1-kr1                      1/1     Running             7             61m
    etcd-prod-silver-master-2-kr2                      1/1     Running             0             58m
    etcd-prod-silver-master-3-kr1                      1/1     Running             0             60m
    kube-apiserver-prod-silver-master-1-kr1            1/1     Running             6             61m
    kube-apiserver-prod-silver-master-2-kr2            1/1     Running             2 (59m ago)   59m
    kube-apiserver-prod-silver-master-3-kr1            1/1     Running             0             60m
    kube-controller-manager-prod-silver-master-1-kr1   1/1     Running             7 (60m ago)   61m
    kube-controller-manager-prod-silver-master-2-kr2   1/1     Running             0             59m
    kube-controller-manager-prod-silver-master-3-kr1   1/1     Running             0             60m
    kube-proxy-5zgnn                                   1/1     Running             0             39m
    kube-proxy-72l5w                                   1/1     Running             0             60m
    kube-proxy-75c2h                                   1/1     Running             0             59m
    kube-proxy-f65tg                                   1/1     Running             0             39m
    kube-proxy-pzm2t                                   1/1     Running             0             39m
    kube-proxy-scpsf                                   1/1     Running             0             61m
    kube-proxy-svbjv                                   1/1     Running             0             39m
    kube-scheduler-prod-silver-master-1-kr1            1/1     Running             7 (60m ago)   61m
    kube-scheduler-prod-silver-master-2-kr2            1/1     Running             0             58m
    kube-scheduler-prod-silver-master-3-kr1            1/1     Running             0             60m
    ```
    
- kubectl이 잘 동작하는 노드(서버)에서 k8s CNI calico 설정 파일 다운로드
    
    ```bash
    curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
    ```
    
- **[중요] 다운받은 calico.yaml 의 pod network 부분 수정**
    - **kubeadm init --pod-network-cidr={ip/subnet} 설정한 {ip/subnet} 으로 변경**
        - **설정 안바꾸고 배포하면 Pod간 통신 X**
        - calico의 default 대역은 192.168.0.0/16 이며 해당 부분을 아래 명령어로 수정
        
        ```bash
        sed -i -e 's?192.168.0.0/16?10.10.0.0/16?g' calico.yaml
        ```
        
- calico.yaml 적용
    
    ```bash
    kubectl apply -f calico.yaml
    ```
    
- k8s core-dns pod 동작 확인
    - 만약 무한정 ContainerCreating이라면 core-dns pod 삭제 수행(자동 재생성)
        - kubectl delete po {{ core-dns-pod-name }} -n kube-system
    
    ```bash
    ==== CNI 배포한 후 Kubernetes Core DNS 상태 ====
    
    $ kubectl get pod --namespace kube-system
    
    NAME                                               READY   STATUS    RESTARTS      AGE
    calico-kube-controllers-7ddc4f45bc-bp78l           1/1     Running   0             8m
    calico-node-44p4t                                  1/1     Running   0             8m
    calico-node-8wgcd                                  1/1     Running   0             8m
    calico-node-lhfd8                                  1/1     Running   0             8m
    calico-node-mr4f2                                  1/1     Running   0             8m
    calico-node-nwmnf                                  1/1     Running   0             8m
    calico-node-p4st7                                  1/1     Running   0             8m
    calico-node-z429n                                  1/1     Running   0             8m
    **coredns-5dd5756b68-2bcfq**                           1/1     **Running**   0             55s
    **coredns-5dd5756b68-gb6vp**                           1/1     **Running**   0             46s
    etcd-prod-silver-master-1-kr1                      1/1     Running   7             72m
    etcd-prod-silver-master-2-kr2                      1/1     Running   0             69m
    etcd-prod-silver-master-3-kr1                      1/1     Running   0             71m
    kube-apiserver-prod-silver-master-1-kr1            1/1     Running   6             72m
    kube-apiserver-prod-silver-master-2-kr2            1/1     Running   2 (70m ago)   70m
    kube-apiserver-prod-silver-master-3-kr1            1/1     Running   0             71m
    kube-controller-manager-prod-silver-master-1-kr1   1/1     Running   7 (71m ago)   72m
    kube-controller-manager-prod-silver-master-2-kr2   1/1     Running   0             70m
    kube-controller-manager-prod-silver-master-3-kr1   1/1     Running   0             71m
    kube-proxy-5zgnn                                   1/1     Running   0             50m
    kube-proxy-72l5w                                   1/1     Running   0             71m
    kube-proxy-75c2h                                   1/1     Running   0             70m
    kube-proxy-f65tg                                   1/1     Running   0             50m
    kube-proxy-pzm2t                                   1/1     Running   0             50m
    kube-proxy-scpsf                                   1/1     Running   0             72m
    kube-proxy-svbjv                                   1/1     Running   0             50m
    kube-scheduler-prod-silver-master-1-kr1            1/1     Running   7 (71m ago)   72m
    kube-scheduler-prod-silver-master-2-kr2            1/1     Running   0             69m
    kube-scheduler-prod-silver-master-3-kr1            1/1     Running   0             71m            60m
    ```
    

## 7. k8s master, worker 정상 설치 및 구동 확인

- kubectl 을 통해 master, worker 노드 현황 및 상태 확인
    
    ```bash
    ==== Master, Worker 노드 모두 Ready 상태 확인 ====
    
    $ kubectl get nodes
    
    NAME                          STATUS   ROLES           AGE   VERSION
    prod-silver-master-1-kr1      Ready    control-plane   88m   v1.28.2
    prod-silver-master-2-kr2      Ready    control-plane   87m   v1.28.2
    prod-silver-master-3-kr1      Ready    control-plane   87m   v1.28.2
    prod-silver-worker-1-kr1      Ready    <none>          67m   v1.28.2
    prod-silver-worker-2-kr2      Ready    <none>          67m   v1.28.2
    prod-silver-worker-db-1-kr1   Ready    <none>          67m   v1.28.2
    prod-silver-worker-db-2-kr2   Ready    <none>          67m   v1.28.2
    ```
    
- CNI 기반 Pod Networking 정상 동작 확인
    
    ```bash
    ==== sample nginx pod 배포 ====
    
    $ echo "apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80" > nginx.yaml
    
    $ kubectl apply -f nginx.yaml
    
    pod/nginx created
    
    $ kubectl logs nginx 
    
    /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
    /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
    10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
    10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
    /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
    /docker-entrypoint.sh: Configuration complete; ready for start up
    2024/01/17 01:39:30 [notice] 1#1: using the "epoll" event method
    2024/01/17 01:39:30 [notice] 1#1: nginx/1.25.3
    2024/01/17 01:39:30 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
    2024/01/17 01:39:30 [notice] 1#1: OS: Linux 5.4.0-99-generic
    2024/01/17 01:39:30 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
    2024/01/17 01:39:30 [notice] 1#1: start worker processes
    2024/01/17 01:39:30 [notice] 1#1: start worker process 29
    ...
    ```
    
- 만약 logs 명령어가 먹통이면 CNI 설정이 잘못된것입니다.
    - CNI 네트워크 설정을 잘못하여 배포
        - master에서 “kubeadm init --pod-network-cidr={ip/subnet}” 설정한 {ip/subnet} 과 calico.yaml “sed -i -e 's?192.168.0.0/16? {ip/subnet}?g' calico.yaml” 이 불일치
        - VM의 Calico 기본 TCP/UDP 개방 X

## 8. k8s 자동완성 설정

- 자동 완성 패키지 설치
    
    ```jsx
    apt-get install bash-completion -y
    echo 'source /etc/profile.d/bash_completion.sh' >>~/.bashrc
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
    source ~/.bashrc
    ```
    

## 9. Kubernetes 설치 성공! Welcome to Kubernetes!
![image](https://github.com/hojun121/k8s_installer/assets/107022839/5d1ef160-fed4-427b-a911-2af69e17a685)


# Kubernetes 동작 및 설치 과정 전체 청사진

- 일반적인 Node(Server)에서 Container 구동 환경
    
    ![Untitled 4](https://github.com/hojun121/k8s_installer/assets/107022839/7058f1e3-85ab-4405-adf4-ed1a40de6c45)

- Kubernetes에서 Node(Server)에서 Container 구동 환경
    
    ![Untitled 5](https://github.com/hojun121/k8s_installer/assets/107022839/09799fb5-718c-4a2e-846d-399d85fe709c)
  
- Kubernetes Pod 란?
    - 1개 이상의 컨테이너 묶음으로 이루어진 논리적 객체
        - Container를 한번 더 격리된 네트워크 공간으로 격리
            
            ![Untitled 6](https://github.com/hojun121/k8s_installer/assets/107022839/9a54a08c-892e-4690-8ce9-70f020b89d5e)

    - Kubernetes 의 기본 실행 단위
- Kubelet 이란?
    - Container Engine과 함께 Pod(Container)를 생성 및 삭제하는 바이너리 실행 파일
    - Host System Daemon 형태로 동작
    - **[중요] 주기적으로 /etc/kubernetes/manifests 디렉토리를 검사하여 yaml 파일이 있을 경우해당 yaml 기반 Pod 생성**
- Kubernetes 설치 과정
    
    (1) Kubernetes는 Master & Worker 구조로 동작하는 시스템
    
    - Kubernetes로 활용할 Node(Master 및 Worker Server)는 반드시 **Kubelet**이 사전 설치
    - 초기 서버 간 kubernetes Clustering은 **kubeadm** 이라는 별도 툴 기반으로 진행
        
        ![Untitled 7](https://github.com/hojun121/k8s_installer/assets/107022839/fa6b2c3c-0ba4-4dc4-a6e8-696ee4425e10)
        
    - 설치 관련 TMI
        - **[kubeadm](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)**은 **k8s 설정에 있어 일부분 자동화 해주는 Tool** 입니다. 해당 Tool 없이 직접 모든걸 Linux 명령어로 설정 가능하지만 공식 홈페이지는 kubeadm 사용을 권장합니다. kubeadm은 k8s 진영에서 직접 개발 및 Release 합니다.
        - 와전 자동화 설치 Tool은 [kubespray](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubespray/)라는 것이 있습니다. Ansible 기반으로 각 Server에 Kubeadm 명령어를 자동으로 수행해주는 Tool 입니다. 마찬가지로 K8s 진영에서 직접 개발 및 Release 합니다. k8s 설치 과정에 숙련된 사람들은 kubespray를 활용한다면 더욱 편하게 설치할 수 있습니다.
    
    (2) kubeadm 명령어를 통해 아래 과정을 거쳐 Master Node 구성
    
    ```bash
    $ kubeadm init
    ```
    
    - /etc/kubernetes/manifests 디렉토리 안에 아래 4개 Yaml 파일 다운로드
        - API Server, Controller, Scheduler, ETCD
    - Kubelet이 주기적으로 해당 파일을 읽어 새로 생성된 4개의 yaml 파일을 기반으로 Pod 생성
    - 우리는 해당 서버를 Master Node라고 부름
        
        ![Untitled 8](https://github.com/hojun121/k8s_installer/assets/107022839/4d8f3f33-431f-46b6-9124-ad23dbdd39b7)
        
    - Master Server 구성이 끝나면 **`kubeadm join ~~`** 명령어들이 출력되며, 해당 명령어를 Worker Node로 활용할 Server에 입력하면 자동으로 K8S Clustering 구성
        
        ![Untitled 9](https://github.com/hojun121/k8s_installer/assets/107022839/8e0b4ea5-b48f-4f16-96e6-acf6a60264a7)
        
    
    (3) Kubectl은 Kubernetes API Server와 통신하기 위한 CLI Tool
    
    - k8s API Server는 기본적으로 https 통신
    - kubectl은 k8s 인증서 파일을 Load해야 정상적인 통신 가능
    
    (4) Kubectl을 통한 CNI(Container Network Interface) 배포
    
    - Kubernetes는 기본적으로 Pod Network 구성이 안되어 있습니다.
    - Pod Network 구성을 위해 CNI를 별도로 배포해야합니다.
    - CNI는 Flannel, Calico, Weavenet 등이 존재
    - CNI 성능 비교 분석표 (본 프로젝트는 calico 채택)
        - 컨테이너 Port Mapping 성능 이슈 발생 시 고려해볼만한 CNI ⇒ [Cillium](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#quick-start)
    
    ![Untitled 10](https://github.com/hojun121/k8s_installer/assets/107022839/e2efe0bb-c0a3-4611-8ac0-0ff299600ee0)

