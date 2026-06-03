#!/usr/bin/env bash
# ============================================================================
#  install.sh — one-line installer (no Node/npm required)
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/dangphamv/helmforge/main/install.sh | bash
#    # or, into a specific repo, run from inside it; pass flags after `-s --`:
#    curl -fsSL .../install.sh | bash -s -- --yes --fe nextjs --be next-api --vcs github
# ============================================================================
set -euo pipefail

REPO="${SDLC_KIT_REPO:-dangphamv/helmforge}"
REF="${SDLC_KIT_REF:-main}"
TARGET="${SDLC_KIT_TARGET:-$(pwd)}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Fetching helmforge ($REPO@$REF)…"
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 --branch "$REF" "https://github.com/$REPO.git" "$TMP/kit" >/dev/null 2>&1 \
    || git clone --depth 1 "https://github.com/$REPO.git" "$TMP/kit" >/dev/null 2>&1
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$REF.tar.gz" | tar -xz -C "$TMP"
  mv "$TMP"/helmforge-* "$TMP/kit"
else
  echo "✗ Need git or curl to download." >&2; exit 1
fi

if [ ! -f "$TMP/kit/setup.sh" ]; then
  echo "✗ setup.sh not found in download." >&2; exit 1
fi

echo "→ Running setup into: $TARGET"
bash "$TMP/kit/setup.sh" --target "$TARGET" "$@"
