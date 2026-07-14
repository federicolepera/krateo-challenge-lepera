#!/usr/bin/env bash
set -euo pipefail

if command -v krateoctl >/dev/null 2>&1; then
  KRATEOCTL_PATH="$(command -v krateoctl)"
  if krateoctl version >/dev/null 2>&1 || krateoctl install --help >/dev/null 2>&1; then
    echo "krateoctl already installed at: $KRATEOCTL_PATH"
    krateoctl version 2>/dev/null || true
    exit 0
  fi

  echo "Found krateoctl at $KRATEOCTL_PATH, but it does not run correctly. Reinstalling..."
fi

if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  brew tap krateoplatformops/krateoctl
  if brew list krateoctl >/dev/null 2>&1; then
    brew reinstall krateoctl
  else
    brew install krateoctl
  fi

  if ! krateoctl version >/dev/null 2>&1 && ! krateoctl install --help >/dev/null 2>&1; then
    echo "krateoctl installation completed, but the binary still does not run correctly." >&2
    echo "Current path: $(command -v krateoctl || true)" >&2
    exit 1
  fi

  echo "krateoctl installed at: $(command -v krateoctl)"
  krateoctl version 2>/dev/null || true
  exit 0
fi

cat <<'EOF' >&2
krateoctl not found and automatic installation is only scripted for macOS with Homebrew.
Install manually, then rerun:
  https://docs.krateo.io/key-concepts/krateoctl/install-upgrade
EOF
exit 1
