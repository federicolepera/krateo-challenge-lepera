#!/usr/bin/env bash
set -euo pipefail

WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-neon-demo}"

kubectl get namespace "$WORKLOAD_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$WORKLOAD_NAMESPACE"
helm upgrade --install neon-postgres-wrapper chart/neon-postgres-chart -n "$WORKLOAD_NAMESPACE" \
  --set databaseName=krateo-challenge-db \
  --set referrer=krateo-challenge-lepera \
  --set seedSampleData=true
