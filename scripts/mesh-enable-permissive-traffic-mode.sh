#!/bin/bash

# shellcheck disable=SC1091
source .env

K8S_NAMESPACE="${K8S_NAMESPACE:-fsm-system}"

kubectl patch meshconfig fsm-mesh-config -n "$K8S_NAMESPACE" \
  -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":true}}}' \
  --type=merge