#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
# set -eox pipefail #safety for script

echo "=============================minikube latest============================================================="
if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 ]]; then #check if virtualization is supported on Linux, xenial fails w 0, bionic works w 2
             echo "virtualization is not supported"
    else
          echo "===================================="
          echo eval "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" 2>/dev/null
          echo "===================================="
          echo "virtualization is supported"
fi

apt-get update -qq && apt-get -qq -y install conntrack #http://conntrack-tools.netfilter.org/
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && mv minikube /usr/local/bin/ # Download minikube
minikube version
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/ # Download kubectl
kubectl version --client
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod 700 get_helm.sh && bash get_helm.sh
helm version
mkdir -p $HOME/.kube $HOME/.minikube

minikube start --profile=minikube --vm-driver=none #the none driver, the kubectl config and credentials generated are owned by root in the root user’s home directory
minikube status #* There is no local cluster named "minikube"
minikube update-context --profile=minikube
`chown -R travis: /home/travis/.minikube/`
eval "$(minikube docker-env --profile=minikube)" && export DOCKER_CLI='docker'

echo "=========================================================================================="
minikube status
kubectl cluster-info

echo "=========================================================================================="
# echo "Waiting for Kubernetes to be ready ..."
# for i in {1..150}; do # Timeout after 5 minutes, 150x2=300 secs
#       if kubectl get pods --namespace=kube-system -lk8s-app=kube-dns|grep Running ; then
#         break
#       fi
#       sleep 2
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
