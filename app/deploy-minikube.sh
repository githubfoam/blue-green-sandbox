#!/bin/bash
set -eox pipefail #safety for script

echo "=============================minikube============================================================="
set -eox pipefail #safety for script
if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 ]]; then #check if virtualization is supported on Linux, xenial fails w 0, bionic works w 2
           echo "virtualization is not supported"
  else
        echo "===================================="
        echo eval "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" 2>/dev/null
        echo "===================================="
        echo "virtualization is supported"
fi


export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export CHANGE_MINIKUBE_NONE_USER=true
export KUBECTL_VERSION=1.18.3
export KUBERNETES_VERSION=1.18.3
export MINIKUBE_VERSION=1.18.3
export MINIKUBE_HOME=$HOME #(string) sets the path for the .minikube directory that minikube uses for state/configuration. Please note: this is used only by minikube https://minikube.sigs.k8s.io/docs/handbook/config
export KUBECONFIG=$HOME/.kube/config
export HELM_VERSION="2.16.9"

apt-get update -qq && apt-get -qqy install conntrack #http://conntrack-tools.netfilter.org/
# curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/ # Download kubectl
# curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && mv minikube /usr/local/bin/ # Download minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v$MINIKUBE_VERSION/minikube-linux-amd64 && chmod +x minikube && mv minikube /usr/local/bin/ # Download minikube
minikube version
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/ # Download kubectl
kubectl version --client
wget -nv https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz && tar xvzf helm-v$HELM_VERSION-linux-amd64.tar.gz && mv linux-amd64/helm linux-amd64/tiller /usr/local/bin
helm version
`mkdir -p $HOME/.kube $HOME/.minikube`
#mkdir -p $HOME/.kube $HOME/.minikube
touch $KUBECONFIG

# minikube start --profile=minikube --vm-driver=none
minikube start --profile=minikube --vm-driver=none --kubernetes-version=v$KUBERNETES_VERSION
minikube update-context --profile=minikube
minikube status
`chown -R travis: /home/travis/.minikube/`
eval "$(minikube docker-env --profile=minikube)" && export DOCKER_CLI='docker'

echo "=========================================================================================="
kubectl version --client #ensure the version
kubectl cluster-info
minikube status

echo "=========================================================================================="
# echo "Waiting for kubernetes to be ready ..."
# for i in {1..150}; do # Timeout after 5 minutes, 150x2=300 secs
#     if kubectl get pods --namespace=kube-system -lk8s-app=kube-dns|grep Running ; then
#       break
#     fi
#     sleep 2
# done
echo echo "Waiting for kubernetes be ready ..."
for i in {1..150}; do # Timeout after 5 minutes, 60x5=300 secs
      if kubectl get pods --namespace=kube-system  | grep ContainerCreating ; then
        sleep 10
      else
        break
      fi
done

echo "============================status check=============================================================="
minikube status
kubectl cluster-info
kubectl get pods --all-namespaces
kubectl get pods -n default
kubectl get pod -o wide #The IP column will contain the internal cluster IP address for each pod.
kubectl get service --all-namespaces # find a Service IP,list all services in all namespaces
