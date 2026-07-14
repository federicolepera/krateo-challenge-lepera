#!/bin/bash
set -euo pipefail

KRATEO_NAMESPACE="${KRATEO_NAMESPACE:-krateo-system}"
FRONTEND_LOCAL_PORT="${FRONTEND_LOCAL_PORT:-30080}"
AUTHN_LOCAL_PORT="${AUTHN_LOCAL_PORT:-30082}"
SNOWPLOW_LOCAL_PORT="${SNOWPLOW_LOCAL_PORT:-30081}"
EVENTS_LOCAL_PORT="${EVENTS_LOCAL_PORT:-30083}"

declare -a BG_PIDS

cleanup() {
  for pid in "${BG_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

get_password() {
  local user="$1"
  kubectl -n "$KRATEO_NAMESPACE" get secret "${user}-password" -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode || true
}

start_port_forward() {
  local svc="$1"
  local remote_port="$2"
  local local_port="$3"
  kubectl -n "$KRATEO_NAMESPACE" port-forward "svc/$svc" "${local_port}:${remote_port}" >/dev/null 2>&1 &
  BG_PIDS+=("$!")
  sleep 1
}

if [[ "${1:-}" == "--credentials-only" ]]; then
  echo "admin: $(get_password admin)"
  echo "cyberjoker: $(get_password cyberjoker)"
  exit 0
fi

start_port_forward frontend 8080 "$FRONTEND_LOCAL_PORT"
start_port_forward authn 8082 "$AUTHN_LOCAL_PORT"
start_port_forward snowplow 8081 "$SNOWPLOW_LOCAL_PORT"
start_port_forward events-presenter 8083 "$EVENTS_LOCAL_PORT"

cat <<EOF
Krateo services:
  Frontend:  http://localhost:${FRONTEND_LOCAL_PORT}
  Auth API:  http://127.0.0.1:${AUTHN_LOCAL_PORT}
  Snowplow:  http://127.0.0.1:${SNOWPLOW_LOCAL_PORT}
  Events:    http://127.0.0.1:${EVENTS_LOCAL_PORT}

Credentials:
  admin:      $(get_password admin)
  cyberjoker: $(get_password cyberjoker)

Press Ctrl+C to stop port-forwards.
EOF

wait
