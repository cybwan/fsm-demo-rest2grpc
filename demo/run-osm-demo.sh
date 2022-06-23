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
MESH_NAME="${MESH_NAME:-osm-edge}"
K8S_NAMESPACE="${K8S_NAMESPACE:-osm-edge-system}"
TEST_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-rest2grpc}"
CERT_MANAGER="${CERT_MANAGER:-tresor}"
CTR_REGISTRY="${CTR_REGISTRY:-cybwan}"
CTR_REGISTRY_CREDS_NAME="${CTR_REGISTRY_CREDS_NAME:-acr-creds}"
DEPLOY_TRAFFIC_SPLIT="${DEPLOY_TRAFFIC_SPLIT:-true}"
CTR_TAG="${CTR_TAG:-$(git rev-parse HEAD)}"
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
TIMEOUT="${TIMEOUT:-300s}"

# For any additional installation arguments. Used heavily in CI.
optionalInstallArgs=$*

exit_error() {
    error="$1"
    echo "$error"
    exit 1
}

# Check if Docker daemon is running
docker info > /dev/null || { echo "Docker daemon is not running"; exit 1; }

# cleanup stale resources from previous runs
./demo/clean-kubernetes.sh

# The demo uses osm's namespace as defined by environment variables, K8S_NAMESPACE
# to house the control plane components.
#
# Note: `osm install` creates the namespace via Helm only if such a namespace already
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
  osm install \
      --osm-namespace "$K8S_NAMESPACE" \
      --verbose \
      --mesh-name "$MESH_NAME" \
      --set=osm.certificateProvider.kind="$CERT_MANAGER" \
      --set=osm.vault.host="$VAULT_HOST" \
      --set=osm.vault.token="$VAULT_TOKEN" \
      --set=osm.vault.protocol="$VAULT_PROTOCOL" \
      --set=osm.image.registry="$CTR_REGISTRY" \
      --set=osm.imagePullSecrets[0].name="$CTR_REGISTRY_CREDS_NAME" \
      --set=osm.image.tag="$CTR_TAG" \
      --set=osm.image.pullPolicy="$IMAGE_PULL_POLICY" \
      --set=osm.enableDebugServer="$ENABLE_DEBUG_SERVER" \
      --set=osm.enableEgress="$ENABLE_EGRESS" \
      --set=osm.enableReconciler="$ENABLE_RECONCILER" \
      --set=osm.deployGrafana="$DEPLOY_GRAFANA" \
      --set=osm.deployJaeger="$DEPLOY_JAEGER" \
      --set=osm.tracing.enable="$DEPLOY_JAEGER" \
      --set=osm.tracing.address="$TRACING_ADDRESS" \
      --set=osm.enableFluentbit="$ENABLE_FLUENTBIT" \
      --set=osm.deployPrometheus="$DEPLOY_PROMETHEUS" \
      --set=osm.sidecarLogLevel="$SIDECAR_LOG_LEVEL" \
      --set=osm.controllerLogLevel="debug" \
      --set=osm.sidecarImage="flomesh/pipy-nightly:latest" \
      --timeout="$TIMEOUT" \
      $optionalInstallArgs
else
  # shellcheck disable=SC2086
  osm install \
      --osm-namespace "$K8S_NAMESPACE" \
      --verbose \
      --mesh-name "$MESH_NAME" \
      --set=osm.certificateProvider.kind="$CERT_MANAGER" \
      --set=osm.image.registry="$CTR_REGISTRY" \
      --set=osm.imagePullSecrets[0].name="$CTR_REGISTRY_CREDS_NAME" \
      --set=osm.image.tag="$CTR_TAG" \
      --set=osm.image.pullPolicy="$IMAGE_PULL_POLICY" \
      --set=osm.enableDebugServer="$ENABLE_DEBUG_SERVER" \
      --set=osm.enableEgress="$ENABLE_EGRESS" \
      --set=osm.enableReconciler="$ENABLE_RECONCILER" \
      --set=osm.deployGrafana="$DEPLOY_GRAFANA" \
      --set=osm.deployJaeger="$DEPLOY_JAEGER" \
      --set=osm.tracing.enable="$DEPLOY_JAEGER" \
      --set=osm.tracing.address="$TRACING_ADDRESS" \
      --set=osm.enableFluentbit="$ENABLE_FLUENTBIT" \
      --set=osm.deployPrometheus="$DEPLOY_PROMETHEUS" \
      --set=osm.sidecarLogLevel="$SIDECAR_LOG_LEVEL" \
      --set=osm.controllerLogLevel="debug" \
      --set=osm.sidecarImage="flomesh/pipy-nightly:latest" \
      --timeout="$TIMEOUT" \
      $optionalInstallArgs
fi

./scripts/mesh-enable-permissive-traffic-mode.sh

./demo/configure-app-namespaces.sh

./demo/deploy-apps.sh