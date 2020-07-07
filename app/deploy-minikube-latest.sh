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

# minikube start --profile=minikube --vm-driver=none --kubernetes-version=v$KUBERNETES_VERSION #the none driver, the kubectl config and credentials generated are owned by root in the root user’s home directory
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
kubectl get pods --all-namespaces;
kubectl get pods -n default;
  # - echo "=============================Inspection============================================================="
  # - kubectl get pod -o wide #The IP column will contain the internal cluster IP address for each pod.
  # - kubectl get service --all-namespaces # find a Service IP,list all services in all namespaces
  # - echo "=============================openEBS============================================================="
  # - pushd $(pwd) && cd app
  # - sudo kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml #install OpenEBS
  # - kubectl get service --all-namespaces # find a Service IP,list all services in all namespaces
  # - kubectl get pods -n openebs -l openebs.io/component-name=openebs-localpv-provisioner #Observe localhost provisioner pod
  # - kubectl get sc #Check the storage Class
  # # openesb component list
  # #https://github.com/openebs/openebs/blob/master/k8s/openebs-operator.yaml
  # - |
  #   echo "Waiting for openebs-localpv-provisioner component to be ready ..."
  #   for i in {1..60}; do # Timeout after 5 minutes, 150x5=300 secs
  #       if sudo kubectl get pods --namespace=openebs -l openebs.io/component-name=openebs-localpv-provisioner | grep Running ; then
  #         break
  #       fi
  #       sleep 5
  #   done
  # - |
  #   echo "Waiting for maya-apiserver component to be ready ..."
  #   for i in {1..60}; do # Timeout after 5 minutes, 150x5=300 secs
  #       if sudo kubectl get pods --namespace=openebs -l openebs.io/component-name=maya-apiserver | grep Running ; then
  #         break
  #       fi
  #       sleep 5
  #   done
  # - |
  #   echo "Waiting for openebs-ndm-operator component to be ready ..."
  #   for i in {1..60}; do # Timeout after 5 minutes, 150x5=300 secs
  #       if sudo kubectl get pods --namespace=openebs -l openebs.io/component-name=openebs-ndm-operator | grep Running ; then
  #         break
  #       fi
  #       sleep 5
  #   done
  # - |
  #   echo "Waiting for openebs to be ready ..."
  #   for i in {1..60}; do # Timeout after 2 minutes, 60x2=300 secs
  #       if sudo kubectl get pods --namespace=openebs | grep Running ; then
  #         break
  #       fi
  #       sleep 2
  #   done
  # - sudo kubectl get pods --all-namespaces
  # - sudo kubectl get pods --namespace=openebs
  # - popd
  # - echo "=============================openEBS============================================================="
  # #Create a PVC #Create an Nginx Pod which consumes OpenEBS Local PV Hospath Storage #openEBS
  # #HPA
  # # - pushd $(pwd) && cd hpa
  # # - minikube addons list
  # # - sudo minikube addons enable metrics-server
  # # - minikube addons list
  # # - sudo kubectl get pods -n kube-system
  # # - sudo kubectl logs -n kube-system deploy/metrics-server
  # # - sudo kubectl get svc -n kube-system
  # # # - sudo ping 10.96.56.228 -c 1 # ping metrics-server   ClusterIP
  # # - kubectl get pods -n kube-system -o wide
  # # - ping 10.224.13.23 -c 1 #   # ping metrics-server  pod IP
  # # - sudo systemctl status kube-apiserver -l
  # # - sudo kubectl top node
  # # - sudo kubectl top pod
  # # - sudo kubectl describe hpa
  # # - |
  # #   sudo minikube start \
  # #   --extra-config=controller-manager.horizontal-pod-autoscaler-upscale-delay=1m \
  # #   --extra-config=controller-manager.horizontal-pod-autoscaler-downscale-delay=1m \
  # #   --extra-config=controller-manager.horizontal-pod-autoscaler-sync-period=10s \
  # #   --extra-config=controller-manager.horizontal-pod-autoscaler-downscale-stabilization=1m
  # # - sudo kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
  # # - sudo kubectl run --generator=run-pod/v1 -it --rm load-generator --image=busybox /bin/sh #Load generator
  # # - while true; do wget -q -O- http://php-apache; done
  # # - kubectl get --raw /apis/metrics.k8s.io/v1beta1
  # # - kubectl get pods -n kube-system | grep metrics-server
  # # - kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq '.'
  # # - kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq '.'
  # # - |
  # #   kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes \
  # #   | jq '[.items [] | {nodeName: .metadata.name, nodeCpu: .usage.cpu, nodeMemory: .usage.memory}]'
  # # - popd
  # #HPA
  # # #nfs-pv-storage
  # - pushd $(pwd) && cd nfs-pv-storage
  # - sudo apt install nfs-kernel-server
  # - sudo mkdir -p /pv/nfs/test-volume
  # - sudo chmod 777 /pv/nfs/test-volume
  # - sudo systemctl status nfs-server
  # - sudo systemctl stop nfs-server
  # - sudo systemctl start nfs-server
  # - sudo systemctl restart nfs-server
  # # - sudo vi /etc/exports
  # # /mnt/nfs/test-volume *(rw,sync,no_subtree_check,insecure)
  # # /pv/nfs/test-volume *(rw,sync,no_subtree_check,insecure)
  # # - sudo exportfs -a
  # # - sudo exportfs -v
  # # - sudo kubectl expose deploy nginx-deploy --port 80 --type NodePort
  # # - sudo apt-get update
  # # - sudo apt-get install -qqy curl
  # # - curl http://localhost/
  # - popd
  # # #nfs-pv-storage
  # # #NGINX as a sample application
  # # - sudo kubectl create deployment nginx --image=nginx
  # # - sudo kubectl get deployments
  # # - sudo kubectl get pods
  # # - sudo kubectl get all --all-namespaces
  # # #NGINX as a sample application
  #
