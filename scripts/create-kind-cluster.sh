#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-krateo-neon-challenge}"
KIND_NODE_IMAGE="${KIND_NODE_IMAGE:-kindest/node:v1.31.0}"

for cmd in docker kind kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop and retry." >&2
  exit 1
fi

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --image "$KIND_NODE_IMAGE"
else
  echo "kind cluster '$CLUSTER_NAME' already exists."
fi

kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
kubectl cluster-info
kubectl get nodes -o wide
