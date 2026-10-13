#!/usr/bin/env bash
set -euo pipefail

# Shah1Tunnel installer (Persian default, English optional)
# Safe installer: downloads ZIP from the repository, extracts to /opt, preserves backups,
# and performs secure cleanup of temporary files.

REPO_OWNER="shah1dev"
REPO_NAME="shah1-core"
BRANCH="feature/installer-farsi"
ZIP_FILENAME="Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip"
RAW_ZIP_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/${ZIP_FILENAME}"
INSTALL_BASE="/opt/shah1tunnel"
LOG_DIR="/var/log/shah1tunnel"
LOG_FILE="${LOG_DIR}/install.log"
TMPDIR=""
CREATED_PATHS=()
LANG_FILE=""

# Default language 'fa' (فارسی). User can choose 'en'.
DEFAULT_LANG="fa"

# Load localized strings
load_locale() {
  local lang=${1:-$DEFAULT_LANG}
  if [[ -f "${PWD}/locales/${lang}.sh" ]]; then
    LANG_FILE="${PWD}/locales/${lang}.sh"
  elif [[ -f "./locales/${lang}.sh" ]]; then
    LANG_FILE="./locales/${lang}.sh"
  else
    # fallback minimal messages in English
    echo "Locale file for '$lang' not found; using bundled English messages" >&2
    LANG_FILE=""
  fi
  if [[ -n "$LANG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LANG_FILE"
  fi
}

# Logging helper
log() {
  mkdir -p "$LOG_DIR"
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"
}

# Cleanup function: remove tmpdir and only paths created by this installer
cleanup() {
  local rc=$?
  if [[ ${#CREATED_PATHS[@]} -gt 0 ]]; then
    for p in "${CREATED_PATHS[@]}"; do
      if [[ -e "$p" ]]; then
        rm -rf -- "$p" || true
        log "پاک‌سازی: حذف $p"
      fi
    done
  fi
  if [[ -n "$TMPDIR" && -d "$TMPDIR" ]]; then
    rm -rf -- "$TMPDIR" || true
    log "پاک‌سازی: حذف دایرکتوری موقت $TMPDIR"
  fi
  log "نصب خاتمه یافت (کد خروج: $rc)"
  return $rc
}
trap cleanup EXIT INT TERM

# Ask language if not set
choose_language() {
  if [[ -f "/etc/shah1tunnel/lang" ]]; then
    LANG=$(cat /etc/shah1tunnel/lang)
  else
    echo
    echo "برای انتخاب زبان نصب، یک گزینه را وارد کنید:"
    echo "1) فارسی (پیش‌فرض)"
    echo "2) English"
    read -r -p "انتخاب [1/2]: " choice || true
    case "$choice" in
      2) LANG=en ;;
      *) LANG=fa ;;
    esac
    mkdir -p /etc/shah1tunnel || true
    echo "$LANG" >/etc/shah1tunnel/lang || true
  fi
  load_locale "$LANG"
}

# Helper to print messages using locale variables, fallback to English literals
l() {
  local key=$1; shift
  case "$key" in
    WELCOME) [[ -n ${L_WELCOME:-} ]] && echo "${L_WELCOME}" || echo "Welcome to Shah1Tunnel installer" ;;
    DOWNLOADING) [[ -n ${L_DOWNLOADING:-} ]] && echo "${L_DOWNLOADING}" || echo "Downloading package..." ;;
    EXTRACTING) [[ -n ${L_EXTRACTING:-} ]] && echo "${L_EXTRACTING}" || echo "Extracting package..." ;;
    BACKING_UP) [[ -n ${L_BACKING_UP:-} ]] && echo "${L_BACKING_UP}" || echo "Backing up existing installation..." ;;
    INSTALL_DONE) [[ -n ${L_INSTALL_DONE:-} ]] && echo "${L_INSTALL_DONE}" || echo "Installation completed." ;;
    ERROR) [[ -n ${L_ERROR:-} ]] && echo "${L_ERROR}" || echo "Error:" ;;
    *) echo "$*" ;;
  esac
}

# Perform download and install
main() {
  echo
  l WELCOME
  log "شروع نصب Shah1Tunnel"

  choose_language

  TMPDIR=$(mktemp -d -t shah1tunnel.XXXXXXXX) || { l ERROR; log "ایجاد دایرکتوری موقت شکست"; exit 1; }
  CREATED_PATHS+=("$TMPDIR")

  local zip_local="$TMPDIR/$ZIP_FILENAME"

  echo
  l DOWNLOADING
  log "دانلود از $RAW_ZIP_URL -> $zip_local"
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl نصب نیست. لطفاً curl را نصب کنید و دوباره اجرا کنید." >&2
    exit 1
  fi

  if ! curl -fsSL "$RAW_ZIP_URL" -o "$zip_local"; then
    log "دانلود بسته شکست خورد"; echo "دانلود بسته شکست خورد" >&2; exit 1
  fi

  # Optional checksum verification if environment variable provided
  if [[ -n "${DOWNLOAD_SHA256:-}" ]]; then
    echo "در حال بررسی checksum..."
    echo "${DOWNLOAD_SHA256}  $zip_local" >"$TMPDIR/checksum.sha256"
    if ! sha256sum -c "$TMPDIR/checksum.sha256"; then
      log "مقادیر checksum هم‌خوانی ندارند"; echo "Checksum mismatch" >&2; exit 1
    fi
  fi

  echo
  l EXTRACTING
  if ! command -v unzip >/dev/null 2>&1; then
    log "unzip نصب نیست. نصب unzip..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y unzip || true
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y unzip || true
    fi
  fi

  mkdir -p "$TMPDIR/extracted"
  if ! unzip -q "$zip_local" -d "$TMPDIR/extracted"; then
    log "استخراج بسته شکست خورد"; echo "Extract failed" >&2; exit 1
  fi

  # Determine install target and backup
  local ts
  ts=$(date +%Y%m%d%H%M%S)
  if [[ -d "$INSTALL_BASE" ]]; then
    l BACKING_UP
    local backup_path="${INSTALL_BASE}.bak.${ts}"
    mv -- "$INSTALL_BASE" "$backup_path"
    log "پشتیبان‌گیری از $INSTALL_BASE به $backup_path"
    CREATED_PATHS+=("$backup_path")
  fi

  # Move extracted files to target
  mkdir -p "${INSTALL_BASE}-${ts}"
  CREATED_PATHS+=("${INSTALL_BASE}-${ts}")
  # Copy contents (preserve attributes)
  cp -a "$TMPDIR/extracted/." "${INSTALL_BASE}-${ts}/"

  # Symlink to stable path
  ln -sfn "${INSTALL_BASE}-${ts}" "$INSTALL_BASE"
  log "انتقال فایل‌ها به ${INSTALL_BASE}-${ts} و لینک ${INSTALL_BASE}"

  # Set permissions
  chmod -R 755 "${INSTALL_BASE}-${ts}" || true

  # If there is a systemd unit provided in package, try to install/enable it safely
  if [[ -f "${INSTALL_BASE}-${ts}/shah1tunnel.service" ]]; then
    sudo cp "${INSTALL_BASE}-${ts}/shah1tunnel.service" /etc/systemd/system/ || true
    sudo systemctl daemon-reload || true
    sudo systemctl enable shah1tunnel.service || true
    sudo systemctl restart shah1tunnel.service || true
    log "واحد systemd نصب/راه‌اندازی شد (در صورت موجود بودن)"
  fi

  echo
  l INSTALL_DONE
  log "نصب موفق"
  echo
  echo "راهنمای اولیه:"
  echo "مسیر نصب: $INSTALL_BASE"
  echo "فایل‌های لاگ نصب: $LOG_FILE"
  echo
  # Keep logs, remove tmpdir via cleanup trap
}

# Run main only if script executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
