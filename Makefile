IMAGE := alpine/fio
APP:="app/deploy-openesb.sh"

deploy-minikube:
	bash app/deploy-minikube.sh

deploy-minikube-latest:
	bash app/deploy-minikube-latest.sh

deploy-bluegreen:
	bash app/deploy-bluegreen.sh

push-image:
	docker push $(IMAGE)

.PHONY: deploy-kind deploy-openesb deploy-dashboard deploy-minikube deploy-istio push-image
