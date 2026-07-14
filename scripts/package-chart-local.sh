#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "$DIST_DIR"
helm repo add marketplace https://marketplace.krateo.io >/dev/null 2>&1 || true
helm repo update marketplace >/dev/null
helm dependency build chart/neon-postgres-chart
helm package chart/neon-postgres-chart --destination "$DIST_DIR"
