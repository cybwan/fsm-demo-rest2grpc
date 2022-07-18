#!/bin/bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Error: expected one argument OS_ARCH"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: expected one argument OS"
  exit 1
fi

if [ -z "$3" ]; then
  echo "Error: expected one argument OSM CLI VERSION"
  exit 1
fi

DEMO_ARCH=$1
DEMO_OS=$2
DEMO_OSM_CLI_V=$3

curl -L https://github.com/flomesh-io/osm-edge/releases/download/${DEMO_OSM_CLI_V}/osm-edge-${DEMO_OSM_CLI_V}-${DEMO_OS}-${DEMO_ARCH}.tar.gz | tar -vxzf -
mv ./${DEMO_OS}-${DEMO_ARCH} bin