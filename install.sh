#!/usr/bin/env bash
set -Eeuo pipefail

OWNER="shah1dev"
REPO="shah1-core"
BRANCH="feature/readme-install"
RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/shah1tunnel-install.XXXXXX")"
trap 'rm -rf "${TEMP_DIR}"' EXIT

fail() {
  printf '[Shah1Tunnel] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_cmd curl

# Prefer the local project files if the repository is already checked out.
if [[ -f "${PWD}/S1T-START.sh" && -f "${PWD}/S1T-CHECKS.sha256" && -f "${PWD}/S1T-INFO-FA.txt" && -f "${PWD}/S1T-CAPSULE/S1T-SOURCE.tar.gz" ]]; then
  exec bash "${PWD}/S1T-START.sh" "$@"
fi

mkdir -p "${TEMP_DIR}/S1T-CAPSULE" || fail "Unable to create temporary working directory."
for rel in \
  S1T-START.sh \
  S1T-CHECKS.sha256 \
  S1T-INFO-FA.txt \
  S1T-CAPSULE/S1T-SOURCE.tar.gz
do
  url="${RAW_BASE}/${rel}"
  dst="${TEMP_DIR}/${rel}"
  mkdir -p "$(dirname "$dst")" || fail "Unable to create parent directory for ${rel}."
  if ! curl -fsSL "$url" -o "$dst"; then
    fail "Failed to download required project file: ${rel}"
  fi
done

exec bash "${TEMP_DIR}/S1T-START.sh" "$@"
