#!/bin/bash
HELM_VERSION=3.15.4
KIND_VERSION=v0.24.0
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
    echo "*********** Instalando Kubernetes Binary *****************"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && $sudoOn install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

_awscli(){
    echo "*********** Instalando AWSCLI *****************"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    $sudoOn ./aws/install
}

_helm(){
    # Link da documentação - https://helm.sh/docs/intro/install/
    wget https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz && \
    tar -xzvf helm-v$HELM_VERSION-linux-amd64.tar.gz && \
    $sudoOn mv linux-amd64/helm /usr/local/bin
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
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-linux-amd64
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
parameters="kubectl docker helm terraform awscli minikube microk8s podman kind k9s all"

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
