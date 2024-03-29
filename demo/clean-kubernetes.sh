#!/bin/bash

set -auo pipefail

# shellcheck disable=SC1091
source .env

TIMEOUT="${TIMEOUT:-90s}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
TEST_NAMESPACE="${TEST_NAMESPACE:-rest2grpc}"

# Clean up Hashicorp Vault deployment
kubectl delete deployment vault -n "$K8S_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"
kubectl delete service vault -n "$K8S_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"

kubectl delete deployment vault -n "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"
kubectl delete service vault -n "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"
kubectl delete namespace "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"

bin/fsm uninstall mesh -f --mesh-name "$MESH_NAME" --fsm-namespace "$K8S_NAMESPACE" --delete-namespace -a

kubectl delete namespace "$TEST_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"
kubectl delete namespace "$K8S_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT"

wait
