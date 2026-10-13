#!/usr/bin/env bash
set -u
set -o pipefail

REPO_OWNER="shah1dev"
REPO_NAME="shah1-core"
REPO_BRANCH="main"
ARCHIVE_NAME="Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip"
ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/raw/${REPO_BRANCH}/${ARCHIVE_NAME}"
RAW_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"
TMP_ROOT="${TMPDIR:-/tmp}/shah1tunnel-install.$$"
WORK_DIR="${TMP_ROOT}/archive"
LOG_FILE="${TMP_ROOT}/install.log"

cleanup() {
  if [ -n "${TMP_ROOT:-}" ] && [ -d "${TMP_ROOT}" ]; then
    rm -rf "${TMP_ROOT}"
  fi
}

trap cleanup EXIT

append_log() {
  printf '%s\n' "$*" | tee -a "$LOG_FILE" >/dev/null 2>&1 || printf '%s\n' "$*" >&2
}

fail() {
  append_log "ERROR: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_cmd curl
require_cmd unzip

mkdir -p "$WORK_DIR" || fail "Unable to create temporary working directory."
: > "$LOG_FILE" || fail "Unable to initialize install log."

append_log "Downloading Shah1Tunnel archive from GitHub..."
archive_path="${TMP_ROOT}/${ARCHIVE_NAME}"
if ! curl -fsSL "$ARCHIVE_URL" -o "$archive_path"; then
  fail "Failed to download the official archive from: $ARCHIVE_URL"
fi

checksum_url="${RAW_BASE_URL}/SHA256SUMS"
if curl -fsSL "$checksum_url" -o "${TMP_ROOT}/SHA256SUMS" 2>/dev/null; then
  append_log "Checksum manifest found; verifying archive integrity..."
  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "${TMP_ROOT}" || exit 1
      sha256sum -c SHA256SUMS --status
    ) || fail "Archive checksum verification failed. Downloaded file does not match the trusted checksum manifest."
  else
    append_log "sha256sum is not available; checksum verification could not be completed on this system."
  fi
else
  append_log "No trusted checksum manifest was found; skipping checksum verification."
fi

append_log "Extracting archive to temporary directory..."
if ! unzip -q "$archive_path" -d "$WORK_DIR"; then
  fail "The downloaded archive could not be extracted."
fi

launcher=""
while IFS= read -r candidate; do
  if [ -n "$candidate" ] && [ -f "$candidate" ]; then
    case "$(basename "$candidate")" in
      S1T-START.sh|start.sh|install.sh|*.sh)
        launcher="$candidate"
        break
        ;;
    esac
  fi
done < <(find "$WORK_DIR" -type f | sort)

if [ -z "$launcher" ]; then
  fail "No executable launcher script was found inside the extracted archive."
fi

append_log "Launching project installer from: $launcher"
chmod +x "$launcher" || fail "Could not make launcher script executable."

if ! bash "$launcher" "$@"; then
  status=$?
  append_log "Project launcher exited with status $status."
  exit "$status"
fi

append_log "Installation completed successfully."
exit 0
