#!/bin/bash

set -auo pipefail

# shellcheck disable=SC1091
source .env
MESH_NAME="${MESH_NAME:-fsm}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
PIPY_INGRESS_SERVICE=${PIPY_INGRESS_SERVICE:-ingress-pipy-controller}
TEST_NAMESPACE="${TEST_NAMESPACE:-rest2grpc}"

SVC_REST2GRPC_CLIENT="rest2grpc-client"

K8S_INGRESS_NODE="${K8S_INGRESS_NODE:-fsm-worker}"

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: AccessControl
apiVersion: policy.openservicemesh.io/v1alpha1
metadata:
  name: pipy-acl-backend
  namespace: $TEST_NAMESPACE
spec:
  backends:
  - name: $SVC_REST2GRPC_CLIENT
    port:
      number: 8888
      protocol: tcp
  sources:
  - kind: IPRange
    name: "10.221.1.0/24"
  - kind: IPRange
    name: "10.221.2.0/24"
  - kind: Service
    namespace: "$INGRESS_PIPY_NAMESPACE"
    name: "$PIPY_INGRESS_SERVICE"
EOF
