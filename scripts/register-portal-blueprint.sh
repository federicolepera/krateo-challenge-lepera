#!/usr/bin/env bash
set -euo pipefail

WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-neon-demo}"
RELEASE_NAME="${RELEASE_NAME:-neon-postgres-database}"
REPO_URL="${REPO_URL:-https://marketplace.krateo.io}"
CHART_NAME="${CHART_NAME:-portal-blueprint-page}"
CHART_VERSION="${CHART_VERSION:-1.0.6}"
VALUES_FILE="${VALUES_FILE:-krateo/portal-blueprint-page-values.yaml}"

kubectl create namespace "$WORKLOAD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade -i "$RELEASE_NAME" "$CHART_NAME" \
  --repo "$REPO_URL" \
  --namespace "$WORKLOAD_NAMESPACE" \
  --create-namespace \
  -f "$VALUES_FILE" \
  --version "$CHART_VERSION" \
  --wait

kubectl -n "$WORKLOAD_NAMESPACE" wait compositiondefinition neon-postgres-database --for condition=Ready=True --timeout=500s

echo "Portal blueprint page registered. Check the Krateo Blueprints page."
