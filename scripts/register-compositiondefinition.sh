#!/usr/bin/env bash
set -euo pipefail

CHART_URL="${CHART_URL:-oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts}"
CHART_VERSION="${CHART_VERSION:-0.1.2}"
CHART_REPO="${CHART_REPO:-neon-postgres-database}"
KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"

kubectl create namespace "$KRATEO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
sed -e "s|oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts|${CHART_URL}|g" \
    -e "s|version: 0.1.2|version: ${CHART_VERSION}|g" \
    -e "s|repo: neon-postgres-database|repo: ${CHART_REPO}|g" \
    krateo/compositiondefinition.yaml | kubectl apply -f -
