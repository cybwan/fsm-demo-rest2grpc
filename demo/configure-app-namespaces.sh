#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

kubectl create namespace "$TEST_NAMESPACE" --save-config
./scripts/create-container-registry-creds.sh "$TEST_NAMESPACE"

# Add namespaces to the mesh
bin/osm namespace add --mesh-name "$MESH_NAME" "$TEST_NAMESPACE"

# Enable metrics for pods belonging to app namespaces
bin/osm metrics enable --namespace "$TEST_NAMESPACE"
