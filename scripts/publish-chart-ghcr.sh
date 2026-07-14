#!/usr/bin/env bash
set -euo pipefail

GITHUB_OWNER="${GITHUB_OWNER:-federicolepera}"
GHCR_REPO_PREFIX="${GHCR_REPO_PREFIX:-krateo-challenge-lepera/charts}"
CHART_DIR="${CHART_DIR:-chart/neon-postgres-chart}"
DIST_DIR="${DIST_DIR:-dist}"

CHART_NAME="$(awk '/^name:/ {print $2}' "$CHART_DIR/Chart.yaml")"
CHART_VERSION="$(awk '/^version:/ {print $2}' "$CHART_DIR/Chart.yaml")"
OCI_BASE="oci://ghcr.io/${GITHUB_OWNER}/${GHCR_REPO_PREFIX}"
PACKAGE_FILE="${DIST_DIR}/${CHART_NAME}-${CHART_VERSION}.tgz"

mkdir -p "$DIST_DIR"
helm package "$CHART_DIR" -d "$DIST_DIR"
helm push "$PACKAGE_FILE" "$OCI_BASE"

CHART_URL="$OCI_BASE" CHART_REPO="$CHART_NAME" CHART_VERSION="$CHART_VERSION" ./scripts/register-compositiondefinition.sh

echo "Published and registered:"
echo "  CHART_URL=$OCI_BASE"
echo "  CHART_REPO=$CHART_NAME"
echo "  CHART_VERSION=$CHART_VERSION"
