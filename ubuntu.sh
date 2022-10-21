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
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
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

main(){
    _container
    echo "*********** Atualizando dados para instalação *****************"
    $sudoOn apt-get -qq update
    $sudoOn apt install unzip curl -y
    export DEBIAN_FRONTEND=noninteractive
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
parameters="kubectl docker helm terraform awscli minikube microk8s podman kind all"

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
