#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "$DIST_DIR"
helm dependency build chart/neon-postgres-chart
helm package chart/neon-postgres-chart --destination "$DIST_DIR"
