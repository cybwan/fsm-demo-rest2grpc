#!/bin/bash

# shellcheck disable=SC1091
source .env
SVC="rest2grpc-server"
TEST_NAMESPACE="${TEST_NAMESPACE:-rest2grpc}"

POD="$(kubectl get pods --selector app=$SVC -n "$TEST_NAMESPACE" --no-headers  | grep 'Running' | awk 'NR==1{print $1}')"
kubectl logs "${POD}" -n "$TEST_NAMESPACE" -c $SVC --tail=100 -f
