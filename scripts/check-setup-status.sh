#!/usr/bin/env bash
set -euo pipefail

WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-neon-demo}"
KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"

echo "== Cluster =="
kubectl cluster-info

echo "\n== Namespaces =="
kubectl get ns "$KRATEO_NAMESPACE" "$WORKLOAD_NAMESPACE" 2>/dev/null || true

echo "\n== Krateo pods =="
kubectl -n "$KRATEO_NAMESPACE" get pods 2>/dev/null || true

echo "\n== CompositionDefinition =="
kubectl -n "$KRATEO_NAMESPACE" get compositiondefinitions.core.krateo.io 2>/dev/null || true

echo "\n== Neon composition CRD =="
kubectl get crd | grep -i neon || true

echo "\n== Workload resources =="
kubectl -n "$WORKLOAD_NAMESPACE" get jobs,pods,secrets 2>/dev/null || true

echo "\n== Neon compositions =="
kubectl -n "$WORKLOAD_NAMESPACE" get neonpostgresdatabases.composition.krateo.io 2>/dev/null || true
