#!/usr/bin/env bash
set -euo pipefail

./scripts/create-kind-cluster.sh
./scripts/install-krateoctl.sh
./scripts/create-krateo-secrets.sh
./scripts/install-krateo-platformops.sh
kubectl apply -f krateo/namespace.yaml

if [[ "${CHART_URL:-}" == "" && "${GITHUB_OWNER:-}" == "" ]]; then
  cat <<'EOF'
Krateo is installed, but the chart has not been published yet.

Next options:
  1. Validate without Krateo:
       ./scripts/deploy-wrapper-chart.sh

  2. Publish/register for Krateo:
       helm registry login ghcr.io -u <github-user>
       GITHUB_OWNER=<github-owner> ./scripts/publish-chart-ghcr.sh
       kubectl apply -f krateo/neonpostgres-test.yaml
EOF
  exit 0
fi

if [[ "${GITHUB_OWNER:-}" != "" ]]; then
  ./scripts/publish-chart-ghcr.sh
else
  ./scripts/register-compositiondefinition.sh
fi

kubectl apply -f krateo/neonpostgres-test.yaml || true
echo "Challenge flow completed. If the Composition CRD is still initializing, retry: kubectl apply -f krateo/neonpostgres-test.yaml"
