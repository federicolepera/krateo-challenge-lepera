#!/usr/bin/env bash
set -euo pipefail

KRATEO_VERSION="${KRATEO_VERSION:-3.0.0}"
KRATEO_TYPE="${KRATEO_TYPE:-nodeport}"
KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"
SKIP_PLAN="${SKIP_PLAN:-false}"

if ! command -v krateoctl >/dev/null 2>&1; then
  echo "krateoctl not found. Run scripts/install-krateoctl.sh first." >&2
  exit 1
fi

kubectl create namespace "$KRATEO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

if [[ "$SKIP_PLAN" != "true" ]]; then
  krateoctl install plan --version "$KRATEO_VERSION" --type "$KRATEO_TYPE" --namespace "$KRATEO_NAMESPACE"
fi

krateoctl install apply --version "$KRATEO_VERSION" --type "$KRATEO_TYPE" --namespace "$KRATEO_NAMESPACE"

kubectl wait deployment --all --for condition=Available=True --namespace "$KRATEO_NAMESPACE" --timeout=800s

while IFS= read -r sts; do
  [[ -z "$sts" ]] && continue
  kubectl rollout status "$sts" --namespace "$KRATEO_NAMESPACE" --timeout=800s
done < <(kubectl get statefulset --namespace "$KRATEO_NAMESPACE" -o name)

echo "Krateo is ready. Portal URL: http://localhost:30080"
