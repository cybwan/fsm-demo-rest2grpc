#!make

CTR_REGISTRY ?= flomesh
CTR_TAG      ?= 1.1.1
DOCKER_BUILDX_OUTPUT ?= type=registry

ARCH_MAP_x86_64 := amd64
ARCH_MAP_arm64 := arm64
ARCH_MAP_aarch64 := arm64

BUILDARCH := $(ARCH_MAP_$(shell uname -m))
BUILDOS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
OSM_CLI_VERSION := v1.1.1

.PHONY: rest2grpc-demo
rest2grpc-demo:
	rm -rf rest2grpc-demo
	git clone https://github.com/flomesh-io/rest2grpc-demo.git

.PHONY: docker-build-rest2grpc
docker-build-rest2grpc: DOCKER_BUILDX_PLATFORM=linux/amd64,linux/arm64
docker-build-rest2grpc: rest2grpc-demo
	docker buildx build --builder fsm --platform=$(DOCKER_BUILDX_PLATFORM) \
	-o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/fsm-demo-rest2grpc:latest \
	-f dockerfiles/Dockerfile.rest2grpc .

check-env:
ifndef CTR_REGISTRY
	$(error CTR_REGISTRY environment variable is not defined; see the .env.example file for more information; then source .env)
endif
ifndef CTR_TAG
	$(error CTR_TAG environment variable is not defined; see the .env.example file for more information; then source .env)
endif

bin/fsm:
	./scripts/install-fsm-cli.sh ${BUILDARCH} ${BUILDOS} ${OSM_CLI_VERSION}

.env: bin/fsm
	cp .env.example .env

.PHONY: kind-up
kind-up:
	./scripts/kind-with-registry.sh

.PHONY: kind-reset
kind-reset: bin/fsm
	kind delete cluster --name fsm

.PHONY: kind-demo
kind-demo: .env kind-up
	./demo/run-fsm-demo.sh

.PHONY: demo-up
demo-up: .env bin/fsm
	./demo/run-fsm-demo.sh

.PHONY: demo-forward
demo-forward: .env bin/fsm
	./scripts/port-forward-rest2grpc-ingress-pipy.sh

.PHONY: demo-reset
demo-reset: .env bin/fsm
	./demo/clean-kubernetes.sh