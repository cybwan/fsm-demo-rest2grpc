#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

./demo/deploy-rest2grpc-server.sh
./demo/deploy-rest2grpc-client.sh
./demo/deploy-rest2grpc-ingress-pipy.sh