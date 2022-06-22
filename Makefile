#!make

CTR_REGISTRY = cybwan
DOCKER_BUILDX_OUTPUT ?= type=registry

.PHONY: rest2grpc-demo
rest2grpc-demo:
	git clone https://github.com/flomesh-io/rest2grpc-demo.git

.PHONY: docker-build-rest2grpc-test
docker-build-rest2grpc: DOCKER_BUILDX_PLATFORM=linux/amd64
docker-build-rest2grpc: rest2grpc-demo
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/rest2grpc:latest -f dockerfiles/Dockerfile.rest2grpc .
