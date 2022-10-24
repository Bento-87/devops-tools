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
        $sudoOn apt-get remove -y docker docker-engine docker.io containerd runc
        $sudoOn apt-get install -y ca-certificates curl gnupg lsb-release
        $sudoOn mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $sudoOn gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
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
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | $sudoOn tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | $sudoOn tee /etc/apt/sources.list.d/hashicorp.list
    $sudoOn apt update && $sudoOn apt install terraform -y
}

_kubectl() {
    if [ $sudoOn ];
    then
        echo "*********** Instalando Kubectl *****************"
        $sudoOn curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | $sudoOn tee /etc/apt/sources.list.d/kubernetes.list
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
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | $sudoOn tee /usr/share/keyrings/helm.gpg > /dev/null
    $sudoOn apt-get install apt-transport-https -y
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | $sudoOn tee /etc/apt/sources.list.d/helm-stable-debian.list
    $sudoOn apt-get update
    $sudoOn apt-get install helm -y
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
    $sudoOn apt-get -y install podman
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
    wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz
    tar -xzvf k9s_Linux_x86_64.tar.gz
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

        $sudoOn apt-get update
        $sudoOn apt-get install cri-o cri-o-runc

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
        git clone https://github.com/Mirantis/cri-dockerd.git
        mkdir bin
        VERSION=$((git describe --abbrev=0 --tags | sed -e 's/v//') || echo $(cat VERSION)-$(git log -1 --pretty='%h')) PRERELEASE=$(grep -q dev <<< "${VERSION}" && echo "pre" || echo "") REVISION=$(git log -1 --pretty='%h')
        go build -ldflags="-X github.com/Mirantis/cri-dockerd/version.Version='$VERSION}' -X github.com/Mirantis/cri-dockerd/version.PreRelease='$PRERELEASE' -X github.com/Mirantis/cri-dockerd/version.BuildTime='$BUILD_DATE' -X github.com/Mirantis/cri-dockerd/version.GitCommit='$REVISION'" -o cri-dockerd

        $sudoON wget https://storage.googleapis.com/golang/getgo/installer_linux
        $sudoON chmod +x ./installer_linux
        $sudoON ./installer_linux
        $sudoON source ~/.bash_profile
$sudoON 
        $sudoON cd cri-dockerd
        $sudoON mkdir bin
        $sudoON go build -o bin/cri-dockerd
        $sudoON mkdir -p /usr/local/bin
        $sudoON install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
        $sudoON cp -a packaging/systemd/* /etc/systemd/system
        $sudoON sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
        $sudoON systemctl daemon-reload
        $sudoON systemctl enable cri-docker.service
        $sudoON systemctl enable --now cri-docker.socket
        
        $sudoOn apt-get update
        $sudoOn apt-get install cri-o cri-o-runc

        $sudoOn systemctl enable crio
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
        $sudoOn sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        $sudoOn apt-get update
        $sudoOn apt-get install -y kubelet kubeadm kubectl ebtables ethtool
        $sudoOn apt-mark hold kubelet kubeadm kubectl
    else 
        echo "*********** Kubeadm in docker não configurado ainda *****************"
    fi
}

main(){
    _container
    echo "*********** Atualizando dados para instalação *****************"
    $sudoOn apt-get -qq update
    $sudoOn apt install unzip curl wget -y
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
