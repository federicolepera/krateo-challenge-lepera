#!/usr/bin/env bash
set -euo pipefail

KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"
DB_USER="${DB_USER:-krateo-db-user}"
DB_PASS="${DB_PASS:-}"
JWT_SIGN_KEY="${JWT_SIGN_KEY:-}"

random_b64() {
  openssl rand -base64 48 | tr -d '\n'
}

get_existing_key() {
  local secret_name="$1"
  local key_name="$2"
  kubectl -n "$KRATEO_NAMESPACE" get secret "$secret_name" -o "jsonpath={.data.${key_name}}" 2>/dev/null | base64 -d 2>/dev/null || true
}

if [[ -z "$JWT_SIGN_KEY" ]]; then
  JWT_SIGN_KEY="$(get_existing_key jwt-sign-key JWT_SIGN_KEY)"
fi
if [[ -z "$JWT_SIGN_KEY" ]]; then
  JWT_SIGN_KEY="$(random_b64)"
fi

if [[ -z "$DB_PASS" ]]; then
  DB_PASS="$(get_existing_key krateo-db DB_PASS)"
fi
if [[ -z "$DB_PASS" ]]; then
  DB_PASS="$(get_existing_key krateo-db-user password)"
fi
if [[ -z "$DB_PASS" ]]; then
  DB_PASS="$(random_b64)"
fi

kubectl create namespace "$KRATEO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$KRATEO_NAMESPACE" create secret generic jwt-sign-key \
  --from-literal=JWT_SIGN_KEY="$JWT_SIGN_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$KRATEO_NAMESPACE" create secret generic krateo-db \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASS="$DB_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$KRATEO_NAMESPACE" create secret generic krateo-db-user \
  --from-literal=username="$DB_USER" \
  --from-literal=password="$DB_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Krateo install secrets are ready in namespace: $KRATEO_NAMESPACE"
