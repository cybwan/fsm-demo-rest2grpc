#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env
VERSION=${1:-v1}
SVC="rest2grpc-server"
USE_PRIVATE_REGISTRY="${USE_PRIVATE_REGISTRY:-true}"
KUBE_CONTEXT=$(kubectl config current-context)
TEST_NAMESPACE="${TEST_NAMESPACE:-rest2grpc}"
KUBERNETES_NODE_OS="${KUBERNETES_NODE_OS:-linux}"
CTR_REGISTRY_CREDS_NAME="${CTR_REGISTRY_CREDS_NAME:-acr-creds}"

kubectl delete deployment "$SVC" -n "$TEST_NAMESPACE"  --ignore-not-found

echo -e "Deploy $SVC Service Account"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: "$SVC"
  namespace: $TEST_NAMESPACE
EOF

echo -e "Deploy $SVC Service"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $SVC
  namespace: $TEST_NAMESPACE
  labels:
    app: $SVC
spec:
  ports:
  - port: 9898
    name: user-port
    appProtocol: grpc
  selector:
    app: $SVC
EOF

echo -e "Deploy $SVC Deployment"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SVC
  namespace: $TEST_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SVC
      version: $VERSION
  template:
    metadata:
      labels:
        app: $SVC
        version: $VERSION
    spec:
      serviceAccountName: "$SVC"
      nodeSelector:
        kubernetes.io/os: ${KUBERNETES_NODE_OS}
      containers:
        - image: "cybwan/osm-edge-demo-rest2grpc:latest"
          imagePullPolicy: Always
          name: $SVC
          ports:
            - name: user-port
              containerPort: 9898
              protocol: TCP
          command: ["java"]
          args: ["-jar","/server-0.0.1.jar","-Dspring.config.location=application-server.yml","--spring.profiles.active=server"]
          env:
            - name: IDENTITY
              value: ${SVC}.${KUBE_CONTEXT}
            - name: GIN_MODE
              value: debug
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
            - name: SERVICE_ACCOUNT
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: spec.serviceAccountName
      imagePullSecrets:
        - name: $CTR_REGISTRY_CREDS_NAME
EOF

kubectl get pods      --no-headers -o wide --selector app="$SVC" -n "$TEST_NAMESPACE"
kubectl get endpoints --no-headers -o wide --selector app="$SVC" -n "$TEST_NAMESPACE"
kubectl get service                -o wide                       -n "$TEST_NAMESPACE"

for x in $(kubectl get service -n "$TEST_NAMESPACE" --selector app="$SVC" --no-headers | awk '{print $1}'); do
    kubectl get service "$x" -n "$TEST_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[*].ip}'
done