#!/usr/bin/env bash
set -euo pipefail

if command -v krateoctl >/dev/null 2>&1; then
  echo "krateoctl already installed: $(krateoctl version 2>/dev/null || echo ok)"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  brew tap krateoplatformops/krateoctl
  brew install krateoctl
  echo "krateoctl installed: $(krateoctl version 2>/dev/null || echo ok)"
  exit 0
fi

cat <<'EOF' >&2
krateoctl not found and automatic installation is only scripted for macOS with Homebrew.
Install manually, then rerun:
  https://docs.krateo.io/key-concepts/krateoctl/install-upgrade
EOF
exit 1
