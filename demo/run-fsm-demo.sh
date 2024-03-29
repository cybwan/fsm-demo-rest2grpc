#!/bin/bash

set -aueo pipefail

if [ ! -f .env ]; then
    echo -e "\nThere is no .env file in the root of this repository."
    echo -e "Copy the values from .env.example into .env."
    echo -e "Modify the values in .env to match your setup.\n"
    echo -e "    cat .env.example > .env\n\n"
    exit 1
fi

# shellcheck disable=SC1091
source .env

# Set meaningful defaults for env vars we expect from .env
MESH_NAME="${MESH_NAME:-fsm}"
K8S_NAMESPACE="${K8S_NAMESPACE:-fsm-system}"
TEST_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-rest2grpc}"
CERT_MANAGER="${CERT_MANAGER:-tresor}"
CTR_REGISTRY="${CTR_REGISTRY:-flomesh}"
CTR_TAG="${CTR_TAG:-1.1.0}"
CTR_REGISTRY_CREDS_NAME="${CTR_REGISTRY_CREDS_NAME:-acr-creds}"
DEPLOY_TRAFFIC_SPLIT="${DEPLOY_TRAFFIC_SPLIT:-true}"
IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-Always}"
ENABLE_DEBUG_SERVER="${ENABLE_DEBUG_SERVER:-false}"
ENABLE_EGRESS="${ENABLE_EGRESS:-false}"
ENABLE_RECONCILER="${ENABLE_RECONCILER:-false}"
DEPLOY_GRAFANA="${DEPLOY_GRAFANA:-false}"
DEPLOY_JAEGER="${DEPLOY_JAEGER:-false}"
TRACING_ADDRESS="${TRACING_ADDRESS:-jaeger.${K8S_NAMESPACE}.svc.cluster.local}"
ENABLE_FLUENTBIT="${ENABLE_FLUENTBIT:-false}"
DEPLOY_PROMETHEUS="${DEPLOY_PROMETHEUS:-false}"
SIDECAR_LOG_LEVEL="${SIDECAR_LOG_LEVEL:-error}"
USE_PRIVATE_REGISTRY="${USE_PRIVATE_REGISTRY:-false}"
OSM_CONTROLLER_REPLICACOUNT="${OSM_CONTROLLER_REPLICACOUNT:-1}"
OSM_INJECTOR_REPLICACOUNT="${OSM_INJECTOR_REPLICACOUNT:-1}"
OSM_BOOTSTRAP_REPLICACOUNT="${OSM_BOOTSTRAP_REPLICACOUNT:-1}"
TIMEOUT="${TIMEOUT:-300s}"
# For any additional installation arguments. Used heavily in CI.
optionalInstallArgs=$*

exit_error() {
    error="$1"
    echo "$error"
    exit 1
}

# Check if Docker daemon is running
#docker info > /dev/null || { echo "Docker daemon is not running"; exit 1; }

# cleanup stale resources from previous runs
./demo/clean-kubernetes.sh

# The demo uses fsm's namespace as defined by environment variables, K8S_NAMESPACE
# to house the control plane components.
#
# Note: `fsm install` creates the namespace via Helm only if such a namespace already
# doesn't exist. We explicitly create the namespace below because of the need to
# create container registry credentials in this namespace for the purpose of testing.
# The side effect of creating the namespace here instead of letting Helm create it is
# that Helm no longer manages namespace creation, and as a result labels that it
# otherwise adds for using as a namespace selector are no longer available.
kubectl create namespace "$K8S_NAMESPACE"
# Mimic Helm namespace label behavior: https://github.com/helm/helm/blob/release-3.2/pkg/action/install.go#L292
kubectl label namespace "$K8S_NAMESPACE" name="$K8S_NAMESPACE"

echo "Certificate Manager in use: $CERT_MANAGER"
if [ "$CERT_MANAGER" = "vault" ]; then
    echo "Installing Hashi Vault"
    ./demo/deploy-vault.sh
fi

if [ "$CERT_MANAGER" = "cert-manager" ]; then
    echo "Installing cert-manager"
    ./demo/deploy-cert-manager.sh
fi

./scripts/create-container-registry-creds.sh "$K8S_NAMESPACE"

# Deploys Xds and Prometheus
echo "Certificate Manager in use: $CERT_MANAGER"
if [ "$CERT_MANAGER" = "vault" ]; then
  # shellcheck disable=SC2086
  bin/fsm install \
      --fsm-namespace "$K8S_NAMESPACE" \
      --mesh-name "$MESH_NAME" \
      --set=fsm.certificateProvider.kind="$CERT_MANAGER" \
      --set=fsm.vault.host="$VAULT_HOST" \
      --set=fsm.vault.token="$VAULT_TOKEN" \
      --set=fsm.vault.protocol="$VAULT_PROTOCOL" \
      --set=fsm.image.registry="$CTR_REGISTRY" \
      --set=fsm.imagePullSecrets[0].name="$CTR_REGISTRY_CREDS_NAME" \
      --set=fsm.image.tag="$CTR_TAG" \
      --set=fsm.image.pullPolicy="$IMAGE_PULL_POLICY" \
      --set=fsm.enableDebugServer="$ENABLE_DEBUG_SERVER" \
      --set=fsm.enableEgress="$ENABLE_EGRESS" \
      --set=fsm.enableReconciler="$ENABLE_RECONCILER" \
      --set=fsm.deployGrafana="$DEPLOY_GRAFANA" \
      --set=fsm.deployJaeger="$DEPLOY_JAEGER" \
      --set=fsm.tracing.enable="$DEPLOY_JAEGER" \
      --set=fsm.tracing.address="$TRACING_ADDRESS" \
      --set=fsm.enableFluentbit="$ENABLE_FLUENTBIT" \
      --set=fsm.deployPrometheus="$DEPLOY_PROMETHEUS" \
      --set=fsm.sidecarLogLevel="$SIDECAR_LOG_LEVEL" \
      --set=fsm.controllerLogLevel="error" \
      --set=fsm.sidecarImage="flomesh/pipy-nightly:latest" \
      --set=fsm.fsmController.replicaCount="${OSM_CONTROLLER_REPLICACOUNT}" \
      --set=fsm.injector.replicaCount="${OSM_INJECTOR_REPLICACOUNT}" \
      --set=fsm.fsmBootstrap.replicaCount="${OSM_BOOTSTRAP_REPLICACOUNT}" \
      --timeout="$TIMEOUT" \
      $optionalInstallArgs
else
  # shellcheck disable=SC2086
  bin/fsm install \
      --fsm-namespace "$K8S_NAMESPACE" \
      --mesh-name "$MESH_NAME" \
      --set=fsm.certificateProvider.kind="$CERT_MANAGER" \
      --set=fsm.image.registry="$CTR_REGISTRY" \
      --set=fsm.imagePullSecrets[0].name="$CTR_REGISTRY_CREDS_NAME" \
      --set=fsm.image.tag="$CTR_TAG" \
      --set=fsm.image.pullPolicy="$IMAGE_PULL_POLICY" \
      --set=fsm.enableDebugServer="$ENABLE_DEBUG_SERVER" \
      --set=fsm.enableEgress="$ENABLE_EGRESS" \
      --set=fsm.enableReconciler="$ENABLE_RECONCILER" \
      --set=fsm.deployGrafana="$DEPLOY_GRAFANA" \
      --set=fsm.deployJaeger="$DEPLOY_JAEGER" \
      --set=fsm.tracing.enable="$DEPLOY_JAEGER" \
      --set=fsm.tracing.address="$TRACING_ADDRESS" \
      --set=fsm.enableFluentbit="$ENABLE_FLUENTBIT" \
      --set=fsm.deployPrometheus="$DEPLOY_PROMETHEUS" \
      --set=fsm.sidecarLogLevel="$SIDECAR_LOG_LEVEL" \
      --set=fsm.controllerLogLevel="error" \
      --set=fsm.sidecarImage="flomesh/pipy-nightly:latest" \
      --set=fsm.fsmController.replicaCount="${OSM_CONTROLLER_REPLICACOUNT}" \
      --set=fsm.injector.replicaCount="${OSM_INJECTOR_REPLICACOUNT}" \
      --set=fsm.fsmBootstrap.replicaCount="${OSM_BOOTSTRAP_REPLICACOUNT}" \
      --timeout="$TIMEOUT" \
      $optionalInstallArgs
fi

./scripts/mesh-enable-permissive-traffic-mode.sh

./demo/configure-app-namespaces.sh

./demo/deploy-apps.sh
