#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "$DIST_DIR"
helm package chart/neon-postgres-chart --destination "$DIST_DIR"
