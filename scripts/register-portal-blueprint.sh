#!/usr/bin/env bash
set -euo pipefail

KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"
WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-neon-demo}"

kubectl create namespace "$KRATEO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$WORKLOAD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f krateo/portal-blueprint-page-compositiondefinition.yaml
kubectl -n "$KRATEO_NAMESPACE" wait compositiondefinition portal-blueprint-page --for condition=Ready=True --timeout=500s

kubectl apply -f krateo/portal-blueprint-page.yaml
kubectl -n "$WORKLOAD_NAMESPACE" wait portalblueprintpage neon-postgres-database --for condition=Ready=True --timeout=500s

echo "Portal blueprint page registered. Check the Krateo Blueprints page."
