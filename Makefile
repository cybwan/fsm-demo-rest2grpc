#!make

CTR_REGISTRY ?= flomesh
CTR_TAG      ?= 1.1.0
DOCKER_BUILDX_OUTPUT ?= type=registry

ARCH_MAP_x86_64 := amd64
ARCH_MAP_arm64 := arm64
ARCH_MAP_aarch64 := arm64

BUILDARCH := $(ARCH_MAP_$(shell uname -m))
BUILDOS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
OSM_CLI_VERSION := v1.1.0

.PHONY: rest2grpc-demo
rest2grpc-demo:
	rm -rf rest2grpc-demo
	git clone https://github.com/flomesh-io/rest2grpc-demo.git

.PHONY: docker-build-rest2grpc
docker-build-rest2grpc: DOCKER_BUILDX_PLATFORM=linux/amd64,linux/arm64
docker-build-rest2grpc: rest2grpc-demo
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) \
	-o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/osm-edge-demo-rest2grpc:latest \
	-f dockerfiles/Dockerfile.rest2grpc .

check-env:
ifndef CTR_REGISTRY
	$(error CTR_REGISTRY environment variable is not defined; see the .env.example file for more information; then source .env)
endif
ifndef CTR_TAG
	$(error CTR_TAG environment variable is not defined; see the .env.example file for more information; then source .env)
endif

bin/osm:
	./scripts/install-osm-cli.sh ${BUILDARCH} ${BUILDOS} ${OSM_CLI_VERSION}

.env: bin/osm
	cp .env.example .env

.PHONY: kind-up
kind-up:
	./scripts/kind-with-registry.sh

.PHONY: kind-reset
kind-reset: bin/osm
	kind delete cluster --name osm

.PHONY: kind-demo
kind-demo: .env kind-up
	./demo/run-osm-demo.sh

.PHONY: demo-up
demo-up: .env bin/osm
	./demo/run-osm-demo.sh

.PHONY: demo-forward
demo-forward: .env bin/osm
	./scripts/port-forward-rest2grpc-ingress-pipy.sh

.PHONY: demo-reset
demo-reset: .env bin/osm
	./demo/clean-kubernetes.sh