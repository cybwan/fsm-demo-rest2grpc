#!/bin/bash

# shellcheck disable=SC1091
source .env
SVC="rest2grpc-client"
TEST_NAMESPACE="${TEST_NAMESPACE:-rest2grpc}"
LOCAL_PORT="${LOCAL_PORT:-8888}"
POD="$(kubectl get pods --selector app=$SVC -n "$TEST_NAMESPACE" --no-headers  | grep 'Running' | awk 'NR==1{print $1}')"

kubectl port-forward --address 0.0.0.0 "$POD" -n "$TEST_NAMESPACE" "$LOCAL_PORT":8888
