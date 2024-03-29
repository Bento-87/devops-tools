#!/bin/bash
_container() {
    echo "*********** Verificando se está rodando em um container Ubuntu"
    if [ -f /.dockerenv ];
    then
        echo "Estou em um container"
        sudoOn=""
    else
        echo "Nao estou em um container"
        sudoOn="sudo"
    fi
}

_docker() {
    if [ $sudoOn ];
    then
        echo "*********** Instalando Docker *****************"
        $sudoOn apt remove -y docker docker-engine docker.io containerd runc
        $sudoOn apt install -y gnupg lsb-release
        $sudoOn mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $sudoOn gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | $sudoOn tee /etc/apt/sources.list.d/docker.list > /dev/null
        $sudoOn apt update
        $sudoOn apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

        $sudoOn groupadd docker
        $sudoOn usermod -aG docker $USER
    else 
        echo "*********** Docker in docker não configurado ainda *****************"
    fi
}

_terraform (){
    echo "*********** Instalando Terraform *****************"
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | $sudoOn tee /etc/apt/trusted.gpg.d/hashicorp.gpg
    echo "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" | $sudoOn tee /etc/apt/sources.list.d/hashicorp.list
    $sudoOn apt update && $sudoOn apt install terraform -y
}

_kubectl() {
    if [ $sudoOn ];
    then
        echo "*********** Instalando Kubectl *****************"
        $sudoOn  curl -fsSLo etc/apt/trusted.gpg.d/kubernetes.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        $sudoOn apt update && $sudoOn apt install kubectl -y
    else 
        echo "*********** Instalando Kubernetes(Container) *****************"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    fi
}

_awscli(){
    echo "*********** Instalando AWSCLI *****************"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    $sudoOn ./aws/install
}

_helm(){
    # Link da documentação - https://helm.sh/docs/intro/install/
    echo "*********** Instalando Helm *****************"
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | $sudoOn tee etc/apt/trusted.gpg.d/helm-stable-debian.gpg > /dev/null
    $sudoOn apt install apt-transport-https -y
    echo "deb [arch=$(dpkg --print-architecture)] https://baltocdn.com/helm/stable/debian/ all main" | $sudoOn tee /etc/apt/sources.list.d/helm-stable-debian.list
    $sudoOn apt update
    $sudoOn apt install helm -y
}

_minikube(){
    # Link da documentação - https://minikube.sigs.k8s.io/docs/start/
    if [ $sudoOn ];
    then
        echo "*********** Instalando Minikube *****************"
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
        $sudoOn dpkg -i minikube_latest_amd64.deb
    else 
        echo "*********** Minikube in docker não configurado ainda *****************"
    fi

}

_microk8s(){
    # Link da documentação - https://microk8s.io/
    if [ $sudoOn ];
    then
        echo "*********** Instalando MicroK8s *****************"
        $sudoOn snap install microk8s --classic
        $sudoOn usermod -a -G microk8s $USER
        $sudoOn chown -f -R $USER ~/.kube
    else 
        echo "*********** MicroK8s in docker não configurado ainda *****************"
    fi
}

_podman(){
    # Link da documentação - https://podman.io/getting-started/installation
    $sudoOn apt -y install podman
}

_kind(){
    # Link da documentação - https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager
    if [ $sudoOn ];
    then
        echo "*********** Instalando Kind *****************"
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.16.0/kind-linux-amd64
        chmod +x ./kind
        $sudoOn mv ./kind /usr/local/bin/kind
    else 
        echo "*********** Kind in docker não configurado ainda *****************"
    fi
}

_k9s(){
    # Link da documentação - https://k9scli.io/topics/install/
    echo "*********** Instalando k9s *****************"
    filename="k9s_Linux_amd64.tar.gz"
    wget https://github.com/derailed/k9s/releases/latest/download/$filename
    tar -xzvf $filename
    chmod +x ./k9s
    $sudoOn mv ./k9s /usr/local/bin/k9s
}

_crio(){
    # Link da documentação - https://github.com/cri-o/cri-o/blob/main/install.md
    if [ $sudoOn ];
    then
        echo "*********** Instalando CRIO *****************"
        OS=xUbuntu_22.04
        VERSION=1.24
        echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | $sudoOn tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
        echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" |$sudoOn tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

        mkdir -p /usr/share/keyrings
        curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | gpg --dearmor | $sudoOn tee /usr/share/keyrings/libcontainers-archive-keyring.gpg
        curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | gpg --dearmor |$sudoOn tee /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

        $sudoOn apt update
        $sudoOn apt install -y cri-o cri-o-runc

        $sudoOn systemctl enable crio
    else 
    echo "*********** CRIO in docker não configurado ainda *****************"
    fi
}

_cridockerd(){
    # Link da documentação - https://github.com/Mirantis/cri-dockerd
    if [ $sudoOn ];
    then
        echo "*********** Instalando cridockerd *****************"
        $sudoOn apt install -y golang-go 

        git clone https://github.com/Mirantis/cri-dockerd.git
    
        cd cri-dockerd
        mkdir bin
        go build -buildvcs=false -o bin/cri-dockerd
        $sudoOn mkdir -p /usr/local/bin
        $sudoOn install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
        $sudoOn cp -a packaging/systemd/* /etc/systemd/system
        $sudoOn sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
        $sudoOn systemctl daemon-reload
        $sudoOn systemctl enable cri-docker.service
        $sudoOn systemctl enable --now cri-docker.socket
        
        cd ../
    else 
    echo "*********** cridockerd in docker não configurado ainda *****************"
    fi
}

_kubeadm(){
    # Link da documentação - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
    if [ $sudoOn ];
    then
        echo "*********** Instalando Kubeadm *****************"
        $sudoOn  curl -fsSLo etc/apt/trusted.gpg.d/kubernetes.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        $sudoOn apt update
        $sudoOn apt install -y kubelet kubeadm kubectl ebtables ethtool
        $sudoOn apt-mark hold kubelet kubeadm kubectl
    else 
        echo "*********** Kubeadm in docker não configurado ainda *****************"
    fi
}

main(){
    _container
    echo "*********** Atualizando dados para instalação *****************"
    $sudoOn apt-get -qq update
    $sudoOn apt install ca-certificates unzip curl wget -y
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    # Create directory to download filess
    mkdir config
    cd config
    # Calling functions
    echo "*********** Iniciando instalação *****************"
    if [[ "$*" == *"all"* ]];
    then
        for param in ${parameters:0:-4};
        do
            _$param
        done
    else 
    echo "Instalando as ferramentas: $getPrameters"
        for param in $getPrameters;
        do
            _$param
        done
    fi
    # Deleting the directory
    cd ../
    $sudoOn rm -rf config
}

# ------------------------------ Main --------------------------------
parameters="kubectl docker helm terraform awscli minikube microk8s podman kind k9s crio kubeadm cridockerd all"

echo "*********** Verificando parametros para instalação *****************"
if [[ "$*" != "" ]];
then
    for parameter in $*; do
        found=0
        for paramVerify in $parameters;
        do
            if [[ "$(echo "$parameter")" == "$paramVerify" ]];
            then
                found=1
            fi
        done
        if [[ "$found" == "0" ]];
        then
            echo "Parametro '$parameter' nao encontrado!!!"
            echo "Parametros aceitos: $parameters"
            exit 1
        fi
    done
    getPrameters="$*"
    echo "Ferramentas a serem instaladas: $getPrameters"
else
    getParameters="all"
    echo "Ferramentas a serem instaladas: ${parameters:0:-4}"
fi

main 
