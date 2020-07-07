#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
# set -eox pipefail #safety for script

echo "====================================##BLUE============================================="
pushd $(pwd) && cd blue
docker image ls && docker container ls
export DOCKER_IMAGE="testblueimage"
export DOCKER_REPO="bluerepo"

docker build -t $DOCKER_IMAGE:$TRAVIS_COMMIT . --file=Dockerfile.nginx

# DOCKER_TOKEN DOCKER_USERNAME are defined on travisci environment variables section
echo $DOCKER_TOKEN |  docker login --username $DOCKER_USERNAME --password-stdin #Login Succeeded

echo $TRAVIS_COMMIT
echo $TRAVIS_TAG
git_sha="${TRAVIS_COMMIT}"

docker tag $DOCKER_IMAGE:$TRAVIS_COMMIT "$DOCKER_USERNAME/$DOCKER_REPO:${git_sha}-${TRAVIS_BRANCH}"
docker push "$DOCKER_USERNAME/$DOCKER_REPO:${git_sha}-${TRAVIS_BRANCH}"

docker run -p 8000:80 "$DOCKER_USERNAME/$DOCKER_REPO:$DOCKER_IMAGE" &
docker image ls
docker container ls
docker logout
popd
echo "====================================##BLUE============================================="



echo "====================================#GREEN============================================="
pushd $(pwd) && cd green
export DOCKER_IMAGE="testgreenimage"
export DOCKER_REPO="greenrepo"
docker build -t $DOCKER_IMAGE:$TRAVIS_COMMIT . --file=Dockerfile.nginx
echo $DOCKER_TOKEN |  docker login --username $DOCKER_USERNAME --password-stdin #Login Succeeded
git_sha="${TRAVIS_COMMIT}"
docker tag $DOCKER_IMAGE:$TRAVIS_COMMIT "$DOCKER_USERNAME/$DOCKER_REPO:${git_sha}-${TRAVIS_BRANCH}"
docker push "$DOCKER_USERNAME/$DOCKER_REPO:${git_sha}-${TRAVIS_BRANCH}"
docker run -p 8000:80 "$DOCKER_USERNAME/$DOCKER_REPO:$DOCKER_IMAGE" &
docker image ls
docker container ls
docker logout
popd
echo "====================================#GREEN============================================="

pushd $(pwd) && cd blue
 kubectl apply -f ./blue-controller.json #Create a replication controller blue pod
popd
pushd $(pwd) && cd green
 kubectl apply -f green-controller.json #Create a replication controller green pod
popd


kubectl apply -f ./blue-green-service.json #Create the service, redirect to blue and make it externally visible, specify "type": "LoadBalancer"



echo "=========================================================================================="
echo echo "Waiting for kubernetes be ready ..."
for i in {1..150}; do # Timeout after 5 minutes, 60x5=300 secs
      if kubectl get pods --namespace=default | grep ContainerCreating ; then
        sleep 10
      else
        break
      fi
done

echo $(minikube service bluegreenlb --url) #debug mode http://10.30.0.90:31089
serviceURL=$(minikube service bluegreenlb --url)
minikube service bluegreenlb --url #Get the URL of the service by running
curl $serviceURL #open the website blue in your browser by using the URL

kubectl get pods --all-namespaces

echo "=========================================================================================="
