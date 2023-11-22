DOCKER_USER=sagemathinc
IMAGE_TAG=latest
BRANCH=master

BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

COMMIT=$(shell git ls-remote -h https://github.com/sagemathinc/cocalc $(BRANCH) | awk '{print $$1}')

ARCH=$(shell uname -m | sed 's/x86_64/-x86_64/;s/arm64/-arm64/;s/aarch64/-arm64/')

cocalc-docker:
	docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker$(ARCH) .
	docker tag cocalc-docker$(ARCH) $(DOCKER_USER)/cocalc-docker$(ARCH):$(IMAGE_TAG)

run-cocalc-docker:
	docker run --name=cocalc-docker -d -p 127.0.0.1:4043:443 cocalc-docker$(ARCH)

rm-cocalc-docker:
	docker stop cocalc-docker
	docker rm cocalc-docker

push-cocalc-docker:
	docker push $(DOCKER_USER)/cocalc-docker$(ARCH):$(IMAGE_TAG)

assemble-cocalc-docker:
	./multiarch.sh $(DOCKER_USER)/cocalc-docker $(IMAGE_TAG)


pytorch:
	cd src && docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker-pytorch . -f pytorch/Dockerfile
	docker tag cocalc-docker-pytorch $(DOCKER_USER)/cocalc-docker-pytorch:$(IMAGE_TAG)

run-pytorch:
	docker run --name=cocalc-docker-pytorch -d -p 127.0.0.1:4043:443 cocalc-docker-pytorch

rm-pytorch:
	docker stop cocalc-docker-pytorch
	docker rm cocalc-docker-pytorch

push-pytorch:
	docker push $(DOCKER_USER)/cocalc-docker-pytorch:$(IMAGE_TAG)
