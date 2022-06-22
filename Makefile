#!make

CTR_REGISTRY = cybwan
DOCKER_BUILDX_OUTPUT ?= type=registry

.PHONY: docker-build-rest2grpc-test
docker-build-rest2grpc: DOCKER_BUILDX_PLATFORM=linux/amd64
docker-build-rest2grpc:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/rest2grpc:latest -f dockerfiles/Dockerfile.rest2grpc .
