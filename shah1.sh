#!/usr/bin/env bash
set -Eeuo pipefail

# shah1-v5 Advanced Online
# FRP 0.71.0 is downloaded online and SHA-256 verified.
# No FRP binary is embedded in this file.
# Optional ShadowTLS v3 is also downloaded online when enabled.
#
# Architecture:
#   - FRP TCP/TLS/mTLS/token control channel
#   - WebSocket + TLS (WSS-equivalent) primary transport
#   - QUIC alternate transport
#   - automatic WSS <-> QUIC failover on connection/health failure
#   - FRP wire protocol v2
#   - optional ShadowTLS v3 transport path (separate TCP listener)
#   - local-only frpc admin API for failover health checks
#   - server allowPorts + maxPortsPerClient=1
#   - systemd sandboxing / non-root services
#   - no changes to Xray or user panels
#
# NOTE: Transport hardening reduces fingerprinting and increases resilience;
# it does not make an IP/domain mathematically invisible or guarantee bypass.

FRP_VERSION="0.71.0"
FRP_BASE_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}"
FRP_SHA256_AMD64="84f27e39f11169f7adcef8e8b70c9329de17747b1f14dad9fb95eef5682ea716"
FRP_SHA256_ARM64="f33c293c275d8fc68c654b6fba8f10b2551d6463d09a9fc9cffb7227eae82266"

SHADOWTLS_VERSION="0.2.25"
SHADOWTLS_BASE_URL="https://github.com/ihciah/shadow-tls/releases/download/v${SHADOWTLS_VERSION}"
SHADOWTLS_SHA256_X86_64="03215c7dd5f70bc4797a84f917b0791175bc1ddee0ce1681b21457fd5f2f573a"

BASE_DIR="/usr/local/lib/shah1-v5"
BIN_DIR="${BASE_DIR}/bin"
RUN_DIR="${BASE_DIR}/run"
ETC_DIR="/etc/shah1-v5"
PKI_DIR="${ETC_DIR}/pki"
SHADOW_DIR="${ETC_DIR}/shadowtls"

SERVER_CONF="${ETC_DIR}/frps.toml"
CLIENT_WSS_CONF="${ETC_DIR}/frpc-wss.toml"
CLIENT_QUIC_CONF="${ETC_DIR}/frpc-quic.toml"
CLIENT_SHADOW_CONF="${ETC_DIR}/frpc-shadow.toml"
SERVER_TOKEN="${ETC_DIR}/server_token"
CLIENT_TOKEN="${ETC_DIR}/client_token"
SHADOW_PASSWORD="${SHADOW_DIR}/password"
SHADOW_SNI_FILE="${SHADOW_DIR}/sni"
SHADOW_SERVER_ENV="${SHADOW_DIR}/server.env"
SHADOW_CLIENT_ENV="${SHADOW_DIR}/client.env"

SERVER_UNIT="shah1-v5-server.service"
CLIENT_UNIT="shah1-v5-client.service"
SHADOW_SERVER_UNIT="shah1-v5-shadow-server.service"
SHADOW_CLIENT_UNIT="shah1-v5-shadow-client.service"

DEFAULT_CONTROL="29064"
DEFAULT_QUIC="29065"
DEFAULT_PROXY="443"
DEFAULT_SHADOW="29443"
DEFAULT_SHADOW_LOCAL="29444"
DEFAULT_SHADOW_SNI="www.microsoft.com"
DEFAULT_SERVER_IP="65.109.206.92"
DEFAULT_OUTSIDE_IP="65.109.205.123"
DEFAULT_CLIENT_LOCAL="443"

WSS_ADMIN_PORT="17401"
QUIC_ADMIN_PORT="17402"
SHADOW_ADMIN_PORT="17403"

log(){ printf '[shah1-v5] %s\n' "$*"; }
err(){ printf '[shah1-v5] ERROR: %s\n' "$*" >&2; }
need_root(){ [[ ${EUID} -eq 0 ]] || { err 'Run as root.'; exit 1; }; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }
valid_port(){ [[ "$1" =~ ^[0-9]+$ && "$1" -ge 1 && "$1" -le 65535 ]]; }
valid_host(){ [[ "$1" =~ ^[A-Za-z0-9_.:-]+$ ]]; }
valid_sni(){ [[ "$1" =~ ^[A-Za-z0-9.-]+$ ]]; }
port_listening_tcp(){ ss -ltnH "sport = :$1" 2>/dev/null | grep -q LISTEN; }
port_listening_udp(){ ss -lunH "sport = :$1" 2>/dev/null | grep -q UNCONN; }
port_reachable_tcp(){ timeout 5 bash -c "</dev/tcp/$1/$2" >/dev/null 2>&1; }

arch_info(){
  case "$(uname -m)" in
    x86_64|amd64)
      ARCH="linux_amd64"
      FRP_SHA256="$FRP_SHA256_AMD64"
      SHADOW_ARCH="x86_64-unknown-linux-musl"
      SHADOW_SHA256="$SHADOWTLS_SHA256_X86_64"
      ;;
    aarch64|arm64)
      ARCH="linux_arm64"
      FRP_SHA256="$FRP_SHA256_ARM64"
      SHADOW_ARCH=""
      SHADOW_SHA256=""
      ;;
    *)
      err "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac
}

ensure_dirs(){
  install -d -m 0755 "$BASE_DIR" "$BIN_DIR" "$RUN_DIR"
  install -d -m 0750 -o root -g frp "$ETC_DIR" "$PKI_DIR"
  install -d -m 0750 -o root -g frp "$SHADOW_DIR"
}

ensure_frp_user(){
  if ! id frp >/dev/null 2>&1; then
    useradd --system --home /nonexistent --shell /usr/sbin/nologin frp
  fi
}

ensure_shadow_user(){
  if ! id shadowtls >/dev/null 2>&1; then
    useradd --system --home /nonexistent --shell /usr/sbin/nologin shadowtls
  fi
}

download_frp(){
  require_cmd curl
  require_cmd sha256sum
  require_cmd tar
  arch_info
  ensure_dirs

  local tgz="/tmp/frp_${FRP_VERSION}_${ARCH}.tar.gz"
  local url="${FRP_BASE_URL}/frp_${FRP_VERSION}_${ARCH}.tar.gz"
  local tmpdir

  log "Downloading official FRP ${FRP_VERSION} (${ARCH})"
  curl -fL --retry 3 --connect-timeout 15 --max-time 180 -o "$tgz" "$url"
  printf '%s  %s\n' "$FRP_SHA256" "$tgz" | sha256sum -c -

  tmpdir="$(mktemp -d)"
  tar -xzf "$tgz" -C "$tmpdir"
  install -m 0755 "$tmpdir/frp_${FRP_VERSION}_${ARCH}/frps" "${BIN_DIR}/frps"
  install -m 0755 "$tmpdir/frp_${FRP_VERSION}_${ARCH}/frpc" "${BIN_DIR}/frpc"
  rm -rf "$tmpdir" "$tgz"
  log "FRP ${FRP_VERSION} verified and installed."
}

download_shadowtls(){
  arch_info
  [[ -n "$SHADOW_ARCH" ]] || {
    err "ShadowTLS v3 optional mode currently supports x86_64 in this script."
    return 1
  }
  require_cmd curl
  require_cmd sha256sum
  ensure_dirs

  local file="/tmp/shadow-tls-${SHADOW_ARCH}"
  local url="${SHADOWTLS_BASE_URL}/shadow-tls-${SHADOW_ARCH}"

  log "Downloading ShadowTLS ${SHADOWTLS_VERSION} (${SHADOW_ARCH})"
  curl -fL --retry 3 --connect-timeout 15 --max-time 180 -o "$file" "$url"
  printf '%s  %s\n' "$SHADOW_SHA256" "$file" | sha256sum -c -
  install -m 0755 "$file" "${BIN_DIR}/shadow-tls"
  rm -f "$file"
  log "ShadowTLS ${SHADOWTLS_VERSION} verified and installed."
}

make_ca_and_server_cert(){
  local server_name="$1"
  ensure_dirs

  if [[ ! -s "$PKI_DIR/ca.key" || ! -s "$PKI_DIR/ca.crt" ]]; then
    log "Generating private CA."
    openssl ecparam -name prime256v1 -genkey -noout -out "$PKI_DIR/ca.key"
    openssl req -x509 -new -sha256 -days 3650 \
      -key "$PKI_DIR/ca.key" \
      -out "$PKI_DIR/ca.crt" \
      -subj "/CN=shah1-v5 private CA"
  fi

  chmod 600 "$PKI_DIR/ca.key"
  chmod 644 "$PKI_DIR/ca.crt"
  chown root:root "$PKI_DIR/ca.key"
  chown root:frp "$PKI_DIR/ca.crt"

  if [[ ! -s "$PKI_DIR/server.key" || ! -s "$PKI_DIR/server.crt" ]]; then
    openssl ecparam -name prime256v1 -genkey -noout -out "$PKI_DIR/server.key"
    openssl req -new -sha256 \
      -key "$PKI_DIR/server.key" \
      -out "$PKI_DIR/server.csr" \
      -subj "/CN=${server_name}"

    {
      echo 'basicConstraints=CA:FALSE'
      echo 'keyUsage=digitalSignature,keyEncipherment'
      echo 'extendedKeyUsage=serverAuth'
      if [[ "$server_name" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "subjectAltName=IP:${server_name}"
      else
        echo "subjectAltName=DNS:${server_name}"
      fi
    } > "$PKI_DIR/server.ext"

    openssl x509 -req -sha256 -days 825 \
      -in "$PKI_DIR/server.csr" \
      -CA "$PKI_DIR/ca.crt" \
      -CAkey "$PKI_DIR/ca.key" \
      -CAcreateserial \
      -out "$PKI_DIR/server.crt" \
      -extfile "$PKI_DIR/server.ext"

    rm -f "$PKI_DIR/server.csr" "$PKI_DIR/server.ext" "$PKI_DIR/ca.srl"
  fi

  chmod 640 "$PKI_DIR/server.key"
  chmod 644 "$PKI_DIR/server.crt"
  chown root:frp "$PKI_DIR/server.key" "$PKI_DIR/server.crt"
}

make_client_cert_and_token(){
  ensure_dirs

  if [[ ! -s "$PKI_DIR/client.key" || ! -s "$PKI_DIR/client.crt" ]]; then
    openssl ecparam -name prime256v1 -genkey -noout -out "$PKI_DIR/client.key"
    openssl req -new -sha256 \
      -key "$PKI_DIR/client.key" \
      -out "$PKI_DIR/client.csr" \
      -subj '/CN=shah1-v5-client'

    cat > "$PKI_DIR/client.ext" <<'EXT'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EXT

    openssl x509 -req -sha256 -days 825 \
      -in "$PKI_DIR/client.csr" \
      -CA "$PKI_DIR/ca.crt" \
      -CAkey "$PKI_DIR/ca.key" \
      -CAcreateserial \
      -out "$PKI_DIR/client.crt" \
      -extfile "$PKI_DIR/client.ext"

    rm -f "$PKI_DIR/client.csr" "$PKI_DIR/client.ext" "$PKI_DIR/ca.srl"
  fi

  chmod 640 "$PKI_DIR/client.key"
  chmod 644 "$PKI_DIR/client.crt"
  chown root:frp "$PKI_DIR/client.key" "$PKI_DIR/client.crt"
}

ensure_token(){
  if [[ ! -s "$SERVER_TOKEN" ]]; then
    umask 077
    openssl rand -hex 32 > "$SERVER_TOKEN"
  fi
  chmod 640 "$SERVER_TOKEN"
  chown root:frp "$SERVER_TOKEN"
}

ensure_shadow_password(){
  install -d -m 0750 -o root -g frp "$SHADOW_DIR"
  if [[ ! -s "$SHADOW_PASSWORD" ]]; then
    umask 077
    openssl rand -hex 32 > "$SHADOW_PASSWORD"
  fi
  chmod 640 "$SHADOW_PASSWORD"
  chown root:shadowtls "$SHADOW_PASSWORD"
}

write_server_candidate(){
  local out="$1" bind_port="$2" quic_port="$3" proxy_port="$4"
  cat > "$out" <<EOF
# Generated by shah1-v5
bindAddr = "0.0.0.0"
bindPort = ${bind_port}
quicBindPort = ${quic_port}

allowPorts = [
  { single = ${proxy_port} }
]
maxPortsPerClient = 1
detailedErrorsToClient = false
userConnTimeout = 10

# Authentication
auth.method = "token"
auth.tokenSource.type = "file"
auth.tokenSource.file.path = "${SERVER_TOKEN}"

# TLS + client certificate verification
transport.tls.force = true
transport.tls.certFile = "${PKI_DIR}/server.crt"
transport.tls.keyFile = "${PKI_DIR}/server.key"
transport.tls.trustedCaFile = "${PKI_DIR}/ca.crt"

# Stable control transport parameters
transport.tcpMuxKeepaliveInterval = 30
transport.tcpKeepalive = 60
transport.heartbeatTimeout = 45
transport.quic.keepalivePeriod = 10
transport.quic.maxIdleTimeout = 30
transport.quic.maxIncomingStreams = 100000

log.to = "console"
log.level = "warn"
log.maxDays = 3
log.disablePrintColor = true
EOF
  chmod 0640 "$out"
  chown root:frp "$out"
}

write_client_candidate(){
  local out="$1" mode="$2" server_addr="$3" server_port="$4" local_port="$5" remote_port="$6" admin_port="$7"
  cat > "$out" <<EOF
# Generated by shah1-v5
serverAddr = "${server_addr}"
serverPort = ${server_port}
loginFailExit = true

# Authentication
auth.method = "token"
auth.tokenSource.type = "file"
auth.tokenSource.file.path = "${CLIENT_TOKEN}"

# Local-only admin API used by the failover watchdog
webServer.addr = "127.0.0.1"
webServer.port = ${admin_port}

# Transport
transport.protocol = "${mode}"
transport.wireProtocol = "v2"
transport.poolCount = 1
transport.tcpMux = true
transport.tcpMuxKeepaliveInterval = 30
transport.dialServerTimeout = 8
transport.dialServerKeepalive = 30
transport.heartbeatInterval = 15
transport.heartbeatTimeout = 45

# TLS / mTLS
transport.tls.enable = true
transport.tls.certFile = "${PKI_DIR}/client.crt"
transport.tls.keyFile = "${PKI_DIR}/client.key"
transport.tls.trustedCaFile = "${PKI_DIR}/ca.crt"
transport.tls.serverName = "${server_addr}"
transport.tls.disableCustomTLSFirstByte = true
EOF

  if [[ "$mode" == "quic" ]]; then
    cat >> "$out" <<EOF
transport.quic.keepalivePeriod = 10
transport.quic.maxIdleTimeout = 30
transport.quic.maxIncomingStreams = 100000
EOF
  fi

  cat >> "$out" <<EOF

[[proxies]]
name = "shah1-v5-443"
type = "tcp"
localIP = "127.0.0.1"
localPort = ${local_port}
remotePort = ${remote_port}
EOF

  chmod 0640 "$out"
  chown root:frp "$out"
}

install_server_unit(){
  cat > "/etc/systemd/system/${SERVER_UNIT}" <<EOF
[Unit]
Description=shah1-v5 FRP Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=frp
Group=frp
ExecStart=${BIN_DIR}/frps -c ${SERVER_CONF}
Restart=on-failure
RestartSec=3
UMask=0077
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
RestrictRealtime=true
RestrictNamespaces=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadOnlyPaths=${ETC_DIR}

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "/etc/systemd/system/${SERVER_UNIT}"
}

install_client_runner(){
  cat > "${RUN_DIR}/frpc-failover-runner.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

BIN_DIR="/usr/local/lib/shah1-v5/bin"
ETC_DIR="/etc/shah1-v5"
RUN_DIR="/usr/local/lib/shah1-v5/run"
LOG_TAG="shah1-v5-runner"

WSS_CONF="${ETC_DIR}/frpc-wss.toml"
QUIC_CONF="${ETC_DIR}/frpc-quic.toml"
SHADOW_CONF="${ETC_DIR}/frpc-shadow.toml"
WSS_ADMIN=17401
QUIC_ADMIN=17402
SHADOW_ADMIN=17403

log(){ printf '[%s] %s\n' "$LOG_TAG" "$*"; }

run_one(){
  local label="$1" conf="$2" admin="$3"
  local pid rc down=0 out

  log "Trying ${label} transport"
  "${BIN_DIR}/frpc" -c "$conf" &
  pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    sleep 5

    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi

    out="$(curl -fsS --max-time 3 "http://127.0.0.1:${admin}/api/status" 2>/dev/null || true)"
    if grep -Eq '"status"[[:space:]]*:[[:space:]]*"running"' <<<"$out"; then
      down=0
    else
      down=$((down + 1))
    fi

    # Four consecutive unhealthy checks (~20s) causes a real transport switch.
    if (( down >= 4 )); then
      log "${label} lost proxy health; switching transport"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 100
    fi
  done

  wait "$pid" 2>/dev/null || rc=$?
  rc="${rc:-0}"
  log "${label} exited with code ${rc}; switching transport"
  return 100
}

trap 'pkill -TERM -P $$ 2>/dev/null || true' EXIT

while true; do
  if run_one "WSS (WebSocket+TLS)" "$WSS_CONF" "$WSS_ADMIN"; then :; fi
  sleep 2
  if run_one "QUIC" "$QUIC_CONF" "$QUIC_ADMIN"; then :; fi
  sleep 2

  if [[ -s "$SHADOW_CONF" && -x "${BIN_DIR}/shadow-tls" ]]; then
    if run_one "ShadowTLS-v3" "$SHADOW_CONF" "$SHADOW_ADMIN"; then :; fi
    sleep 2
  fi
done
EOF
  chmod 0750 "${RUN_DIR}/frpc-failover-runner.sh"
  chown root:frp "${RUN_DIR}/frpc-failover-runner.sh"
}

install_client_unit(){
  cat > "/etc/systemd/system/${CLIENT_UNIT}" <<EOF
[Unit]
Description=shah1-v5 FRP Client with WSS-QUIC-ShadowTLS failover
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=frp
Group=frp
ExecStart=${RUN_DIR}/frpc-failover-runner.sh
Restart=always
RestartSec=3
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
RestrictRealtime=true
RestrictNamespaces=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadOnlyPaths=${ETC_DIR}

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "/etc/systemd/system/${CLIENT_UNIT}"
}

write_shadow_server_unit(){
  local listen_port="$1"
  local password sni
  password="$(cat "$SHADOW_PASSWORD")"
  sni="$(cat "$SHADOW_SNI_FILE")"
  umask 077
  cat > "$SHADOW_SERVER_ENV" <<EOF
SHADOWTLS_PASSWORD=${password}
SHADOWTLS_SNI=${sni}
EOF
  chmod 0640 "$SHADOW_SERVER_ENV"
  chown root:shadowtls "$SHADOW_SERVER_ENV"

  cat > "/etc/systemd/system/${SHADOW_SERVER_UNIT}" <<EOF
[Unit]
Description=shah1-v5 ShadowTLS v3 Server
After=network-online.target ${SERVER_UNIT}
Wants=network-online.target
Requires=${SERVER_UNIT}

[Service]
Type=simple
User=shadowtls
Group=shadowtls
EnvironmentFile=${SHADOW_SERVER_ENV}
ExecStart=${BIN_DIR}/shadow-tls --v3 --strict server --listen 0.0.0.0:${listen_port} --server 127.0.0.1:${DEFAULT_CONTROL} --tls \${SHADOWTLS_SNI}:443 --password \${SHADOWTLS_PASSWORD}
Restart=on-failure
RestartSec=3
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
RestrictRealtime=true
RestrictNamespaces=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "/etc/systemd/system/${SHADOW_SERVER_UNIT}"
}

write_shadow_client_unit(){
  local remote_ip="$1" remote_port="$2" local_port="$3"
  local password sni
  password="$(cat "$SHADOW_PASSWORD")"
  sni="$(cat "$SHADOW_SNI_FILE")"
  umask 077
  cat > "$SHADOW_CLIENT_ENV" <<EOF
SHADOWTLS_PASSWORD=${password}
SHADOWTLS_SNI=${sni}
EOF
  chmod 0640 "$SHADOW_CLIENT_ENV"
  chown root:shadowtls "$SHADOW_CLIENT_ENV"

  cat > "/etc/systemd/system/${SHADOW_CLIENT_UNIT}" <<EOF
[Unit]
Description=shah1-v5 ShadowTLS v3 Client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=shadowtls
Group=shadowtls
EnvironmentFile=${SHADOW_CLIENT_ENV}
ExecStart=${BIN_DIR}/shadow-tls --v3 --strict client --listen 127.0.0.1:${local_port} --server ${remote_ip}:${remote_port} --sni \${SHADOWTLS_SNI} --password \${SHADOWTLS_PASSWORD}
Restart=always
RestartSec=3
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
RestrictRealtime=true
RestrictNamespaces=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "/etc/systemd/system/${SHADOW_CLIENT_UNIT}"
}

activate_server_after_verify(){
  local candidate="$1"
  if ! "${BIN_DIR}/frps" verify -c "$candidate"; then
    err 'frps verify FAILED. Nothing was activated.'
    return 1
  fi

  install -m 0640 -o root -g frp "$candidate" "$SERVER_CONF"
  install_server_unit
  systemctl daemon-reload
  systemctl enable --now "$SERVER_UNIT"

  if ! systemctl is-active --quiet "$SERVER_UNIT"; then
    err 'Server service failed after successful verification.'
    systemctl --no-pager --full status "$SERVER_UNIT" || true
    journalctl -u "$SERVER_UNIT" -n 50 --no-pager || true
    return 1
  fi
}

activate_client_configs(){
  local wss="$1" quic="$2" shadow="${3:-}"
  "${BIN_DIR}/frpc" verify -c "$wss"
  "${BIN_DIR}/frpc" verify -c "$quic"
  if [[ -n "$shadow" && -s "$shadow" ]]; then
    "${BIN_DIR}/frpc" verify -c "$shadow"
  fi

  install -m 0640 -o root -g frp "$wss" "$CLIENT_WSS_CONF"
  install -m 0640 -o root -g frp "$quic" "$CLIENT_QUIC_CONF"
  if [[ -n "$shadow" && -s "$shadow" ]]; then
    install -m 0640 -o root -g frp "$shadow" "$CLIENT_SHADOW_CONF"
  else
    rm -f "$CLIENT_SHADOW_CONF"
  fi

  install_client_runner
  install_client_unit
  systemctl daemon-reload

  if [[ -s "$SHADOW_PASSWORD" && -s "$SHADOW_SNI_FILE" && -x "${BIN_DIR}/shadow-tls" && -f "/etc/systemd/system/${SHADOW_CLIENT_UNIT}" ]]; then
    systemctl enable --now "$SHADOW_CLIENT_UNIT"
  else
    systemctl disable --now "$SHADOW_CLIENT_UNIT" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SHADOW_CLIENT_UNIT}"
    systemctl daemon-reload
  fi

  systemctl enable --now "$CLIENT_UNIT"
  if ! systemctl is-active --quiet "$CLIENT_UNIT"; then
    err 'Client service failed after successful config verification.'
    systemctl --no-pager --full status "$CLIENT_UNIT" || true
    journalctl -u "$CLIENT_UNIT" -n 50 --no-pager || true
    return 1
  fi
}

apply_ufw_restrictions(){
  local outside_ip="$1" control="$2" quic="$3" shadow_port="$4"
  command -v ufw >/dev/null 2>&1 || return 0
  ufw status | grep -q '^Status: active' || return 0
  valid_host "$outside_ip" || return 0

  log "UFW is active: restricting control/alternate ports to ${outside_ip}."
  ufw allow from "$outside_ip" to any port "$control" proto tcp >/dev/null
  ufw allow from "$outside_ip" to any port "$quic" proto udp >/dev/null
  if valid_port "$shadow_port"; then
    ufw allow from "$outside_ip" to any port "$shadow_port" proto tcp >/dev/null
  fi
}

check_tls13_sni(){
  local sni="$1"
  valid_sni "$sni" || { err 'Invalid camouflage SNI.'; return 1; }
  log "Checking TLS 1.3 support for ${sni}:443..."
  if ! timeout 10 openssl s_client -tls1_3 -connect "${sni}:443" -servername "$sni" </dev/null 2>/dev/null | grep -q 'Protocol.*TLSv1.3'; then
    err "${sni}:443 did not confirm TLS 1.3 from this server. Choose another SNI."
    return 1
  fi
}

make_bootstrap(){
  local server_addr="$1" control="$2" quic_port="$3" proxy_port="$4" shadow_port="$5" shadow_enabled="$6"
  local tmp payload file

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  printf '%s\n' "$server_addr" > "$tmp/server_addr"
  printf '%s\n' "$control" > "$tmp/server_port"
  printf '%s\n' "$quic_port" > "$tmp/quic_port"
  printf '%s\n' "$proxy_port" > "$tmp/proxy_port"
  printf '%s\n' "$shadow_enabled" > "$tmp/shadow_enabled"
  printf '%s\n' "$shadow_port" > "$tmp/shadow_port"
  install -m 0600 "$SERVER_TOKEN" "$tmp/token"
  install -m 0644 "$PKI_DIR/ca.crt" "$tmp/ca.crt"
  install -m 0644 "$PKI_DIR/client.crt" "$tmp/client.crt"
  install -m 0600 "$PKI_DIR/client.key" "$tmp/client.key"

  if [[ "$shadow_enabled" == 'yes' ]]; then
    install -m 0600 "$SHADOW_PASSWORD" "$tmp/shadow_password"
    install -m 0644 "$SHADOW_SNI_FILE" "$tmp/shadow_sni"
  fi

  if [[ "$shadow_enabled" == 'yes' ]]; then
    tar -C "$tmp" -czf "$tmp/payload.tgz" \
      server_addr server_port quic_port proxy_port shadow_enabled shadow_port token ca.crt client.crt client.key shadow_password shadow_sni
  else
    tar -C "$tmp" -czf "$tmp/payload.tgz" \
      server_addr server_port quic_port proxy_port shadow_enabled shadow_port token ca.crt client.crt client.key
  fi

  payload="$(openssl base64 -A -in "$tmp/payload.tgz")"
  file="/root/shah1-v5-client-bootstrap.txt"
  printf 'SHAH1V5:%s\n' "$payload" > "$file"
  chmod 0600 "$file"

  echo "SHAH1V5:${payload}"
  echo
  echo "Saved copy: ${file}"
  trap - RETURN
  rm -rf "$tmp"
}

server_mode(){
  require_cmd openssl
  require_cmd ss
  require_cmd curl
  require_cmd tar
  require_cmd sha256sum
  require_cmd timeout

  local control quic proxy server_name outside_ip shadow_enable shadow_port shadow_sni
  local candidate

  read -r -p "Control/bind TCP port [${DEFAULT_CONTROL}]: " control
  control="${control:-$DEFAULT_CONTROL}"
  read -r -p "QUIC UDP port [${DEFAULT_QUIC}]: " quic
  quic="${quic:-$DEFAULT_QUIC}"
  read -r -p "Public proxy port [${DEFAULT_PROXY}]: " proxy
  proxy="${proxy:-$DEFAULT_PROXY}"
  read -r -p "Server IP/hostname [${DEFAULT_SERVER_IP}]: " server_name
  server_name="${server_name:-$DEFAULT_SERVER_IP}"
  read -r -p "Outside IP [${DEFAULT_OUTSIDE_IP}]: " outside_ip
  outside_ip="${outside_ip:-$DEFAULT_OUTSIDE_IP}"
  read -r -p "Enable ShadowTLS v3? [y/N]: " shadow_enable
  shadow_enable="${shadow_enable:-N}"

  valid_port "$control" || { err 'Invalid control port.'; return 1; }
  valid_port "$quic" || { err 'Invalid QUIC port.'; return 1; }
  valid_port "$proxy" || { err 'Invalid proxy port.'; return 1; }
  valid_host "$server_name" || { err 'Invalid server IP/hostname.'; return 1; }
  [[ "$control" != "$proxy" ]] || { err 'Control and proxy ports must differ.'; return 1; }
  [[ "$control" != "$quic" ]] || { err 'TCP control and UDP QUIC ports must differ.'; return 1; }
  [[ "$quic" != "$proxy" ]] || { err 'QUIC and proxy ports must differ.'; return 1; }

  if port_listening_tcp "$control"; then err "TCP ${control} is already in use."; return 1; fi
  if port_listening_udp "$quic"; then err "UDP ${quic} is already in use."; return 1; fi
  if port_listening_tcp "$proxy"; then err "TCP ${proxy} is already in use. Existing service untouched."; return 1; fi

  shadow_enable="${shadow_enable,,}"
  shadow_port=""
  shadow_sni=""
  if [[ "$shadow_enable" == 'y' || "$shadow_enable" == 'yes' ]]; then
    shadow_enable='yes'
    if [[ "$(uname -m)" != 'x86_64' && "$(uname -m)" != 'amd64' ]]; then
      err 'ShadowTLS v3 mode in this file requires x86_64/amd64.'
      return 1
    fi
    read -r -p "ShadowTLS public TCP port [${DEFAULT_SHADOW}]: " shadow_port
    shadow_port="${shadow_port:-$DEFAULT_SHADOW}"
    read -r -p "Camouflage SNI [${DEFAULT_SHADOW_SNI}]: " shadow_sni
    shadow_sni="${shadow_sni:-$DEFAULT_SHADOW_SNI}"
    valid_port "$shadow_port" || { err 'Invalid ShadowTLS port.'; return 1; }
    valid_sni "$shadow_sni" || { err 'Invalid camouflage SNI.'; return 1; }
    [[ "$shadow_port" != "$control" && "$shadow_port" != "$proxy" && "$shadow_port" != "$quic" ]] || { err 'ShadowTLS port conflicts with another selected port.'; return 1; }
    if port_listening_tcp "$shadow_port"; then err "TCP ${shadow_port} is already in use."; return 1; fi
    check_tls13_sni "$shadow_sni" || return 1
  else
    shadow_enable='no'
  fi

  download_frp
  ensure_frp_user
  make_ca_and_server_cert "$server_name"
  make_client_cert_and_token
  ensure_token

  if [[ "$shadow_enable" == 'yes' ]]; then
    download_shadowtls
    ensure_shadow_user
    ensure_shadow_password
    printf '%s\n' "$shadow_sni" > "$SHADOW_SNI_FILE"
    chmod 0640 "$SHADOW_SNI_FILE"
    chown root:frp "$SHADOW_SNI_FILE"
  fi

  candidate="$(mktemp)"
  trap 'rm -f "$candidate"' RETURN
  write_server_candidate "$candidate" "$control" "$quic" "$proxy"
  log 'Running frps verify before activation...'
  activate_server_after_verify "$candidate" || return 1

  if [[ "$shadow_enable" == 'yes' ]]; then
    write_shadow_server_unit "$shadow_port"
    systemctl daemon-reload
    systemctl enable --now "$SHADOW_SERVER_UNIT"
    if ! systemctl is-active --quiet "$SHADOW_SERVER_UNIT"; then
      err 'ShadowTLS server did not start.'
      journalctl -u "$SHADOW_SERVER_UNIT" -n 50 --no-pager || true
      return 1
    fi
  else
    systemctl disable --now "$SHADOW_SERVER_UNIT" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SHADOW_SERVER_UNIT}"
    systemctl daemon-reload
  fi

  apply_ufw_restrictions "$outside_ip" "$control" "$quic" "${shadow_port:-0}"

  echo
  echo '============================================================'
  echo ' shah1-v5 SERVER READY'
  echo " Control : ${control}/tcp (WSS via WebSocket+TLS)"
  echo " QUIC    : ${quic}/udp"
  echo " Proxy   : ${proxy}/tcp"
  echo ' Wire    : v2'
  echo ' Primary : WSS via WebSocket+TLS'
  echo ' TLS     : REQUIRED'
  echo ' mTLS    : REQUIRED'
  echo ' Auth    : RANDOM TOKEN FILE'
  echo ' Limit   : 1 proxy / client'
  if [[ "$shadow_enable" == 'yes' ]]; then
    echo " Shadow  : v3 on ${shadow_port}/tcp"
    echo " SNI     : ${shadow_sni}"
  else
    echo ' Shadow  : OFF'
  fi
  echo ' Verify  : PASSED BEFORE ACTIVATION'
  echo '============================================================'
  echo
  echo 'ONE-LINE CLIENT BOOTSTRAP (KEEP PRIVATE):'
  make_bootstrap "$server_name" "$control" "$quic" "$proxy" "${shadow_port:-0}" "$shadow_enable"
  echo
  echo 'Copy the COMPLETE line starting with SHAH1V5: to the outside server.'
  echo 'Do not publish the bootstrap line.'

  trap - RETURN
  rm -f "$candidate"
}

client_mode(){
  require_cmd openssl
  require_cmd ss
  require_cmd curl
  require_cmd tar
  require_cmd sha256sum
  require_cmd timeout

  local bootstrap tmp payload server_addr server_port quic_port proxy_port shadow_enabled shadow_port shadow_sni
  local local_port remote_port candidate_wss candidate_quic candidate_shadow

  echo 'Paste the FULL SHAH1V5 bootstrap line from the Iran server.'
  read -r -p 'Bootstrap: ' bootstrap
  if [[ -f "$bootstrap" ]]; then bootstrap="$(cat "$bootstrap")"; fi
  bootstrap="${bootstrap//$'\r'/}"
  [[ "$bootstrap" == SHAH1V5:* ]] || { err 'Invalid bootstrap. It must start with SHAH1V5:'; return 1; }

  payload="${bootstrap#SHAH1V5:}"
  [[ -n "$payload" ]] || { err 'Bootstrap payload is empty.'; return 1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  if ! printf '%s' "$payload" | openssl base64 -d -A > "$tmp/payload.tgz" 2>/dev/null; then
    err 'Bootstrap decoding failed.'
    return 1
  fi
  tar -xzf "$tmp/payload.tgz" -C "$tmp" || { err 'Bootstrap archive is invalid.'; return 1; }

  for f in server_addr server_port quic_port proxy_port shadow_enabled shadow_port token ca.crt client.crt client.key; do
    [[ -s "$tmp/$f" ]] || { err "Bootstrap missing: $f"; return 1; }
  done

  server_addr="$(cat "$tmp/server_addr")"
  server_port="$(cat "$tmp/server_port")"
  quic_port="$(cat "$tmp/quic_port")"
  proxy_port="$(cat "$tmp/proxy_port")"
  shadow_enabled="$(cat "$tmp/shadow_enabled")"
  shadow_port="$(cat "$tmp/shadow_port")"

  valid_host "$server_addr" || { err 'Invalid server address.'; return 1; }
  valid_port "$server_port" || { err 'Invalid control port.'; return 1; }
  valid_port "$quic_port" || { err 'Invalid QUIC port.'; return 1; }
  valid_port "$proxy_port" || { err 'Invalid proxy port.'; return 1; }

  read -r -p "Local service port [${DEFAULT_CLIENT_LOCAL}]: " local_port
  local_port="${local_port:-$DEFAULT_CLIENT_LOCAL}"
  read -r -p "Remote public port [${proxy_port}]: " remote_port
  remote_port="${remote_port:-$proxy_port}"
  valid_port "$local_port" || { err 'Invalid local port.'; return 1; }
  valid_port "$remote_port" || { err 'Invalid remote port.'; return 1; }
  [[ "$remote_port" == "$proxy_port" ]] || { err "Remote port must match server allowlist (${proxy_port})."; return 1; }

  log "Checking TCP control reachability to ${server_addr}:${server_port}..."
  if ! port_reachable_tcp "$server_addr" "$server_port"; then
    err 'TCP control port is not reachable from this server.'
    return 1
  fi

  download_frp
  ensure_frp_user
  ensure_dirs

  install -m 0640 -o root -g frp "$tmp/token" "$CLIENT_TOKEN"
  install -m 0644 -o root -g frp "$tmp/ca.crt" "$PKI_DIR/ca.crt"
  install -m 0644 -o root -g frp "$tmp/client.crt" "$PKI_DIR/client.crt"
  install -m 0640 -o root -g frp "$tmp/client.key" "$PKI_DIR/client.key"

  candidate_shadow=''
  candidate_wss="$(mktemp)"
  candidate_quic="$(mktemp)"
  trap 'rm -rf "$tmp" "$candidate_wss" "$candidate_quic" "$candidate_shadow"' RETURN

  write_client_candidate "$candidate_wss" 'websocket' "$server_addr" "$server_port" "$local_port" "$remote_port" "$WSS_ADMIN_PORT"
  write_client_candidate "$candidate_quic" 'quic' "$server_addr" "$quic_port" "$local_port" "$remote_port" "$QUIC_ADMIN_PORT"

  if [[ "$shadow_enabled" == 'yes' ]]; then
    [[ -s "$tmp/shadow_password" && -s "$tmp/shadow_sni" ]] || { err 'ShadowTLS bootstrap data missing.'; return 1; }
    [[ "$(uname -m)" == 'x86_64' || "$(uname -m)" == 'amd64' ]] || { err 'ShadowTLS mode currently requires x86_64/amd64.'; return 1; }

    if port_listening_tcp "$DEFAULT_SHADOW_LOCAL" || port_listening_udp "$DEFAULT_SHADOW_LOCAL"; then
      err "Local ShadowTLS listener port ${DEFAULT_SHADOW_LOCAL} is already in use."
      return 1
    fi
    install -m 0640 -o root -g frp "$tmp/shadow_password" "$SHADOW_PASSWORD"
    install -m 0644 -o root -g frp "$tmp/shadow_sni" "$SHADOW_SNI_FILE"
    ensure_shadow_user
    download_shadowtls

  fi

  if [[ "$shadow_enabled" == 'yes' ]]; then
    candidate_shadow="$(mktemp)"
    write_client_candidate "$candidate_shadow" 'tcp' '127.0.0.1' "$DEFAULT_SHADOW_LOCAL" "$local_port" "$remote_port" "$SHADOW_ADMIN_PORT"
    sed -i "s|transport.tls.serverName = \".*\"|transport.tls.serverName = \"${server_addr}\"|" "$candidate_shadow"

    systemctl disable --now "$SHADOW_CLIENT_UNIT" 2>/dev/null || true
    write_shadow_client_unit "$server_addr" "$shadow_port" "$DEFAULT_SHADOW_LOCAL"
    systemctl daemon-reload
    systemctl enable --now "$SHADOW_CLIENT_UNIT"
    if ! systemctl is-active --quiet "$SHADOW_CLIENT_UNIT"; then
      err 'ShadowTLS client did not start.'
      journalctl -u "$SHADOW_CLIENT_UNIT" -n 50 --no-pager || true
      return 1
    fi
  else
    rm -f "$CLIENT_SHADOW_CONF"
    systemctl disable --now "$SHADOW_CLIENT_UNIT" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SHADOW_CLIENT_UNIT}"
    systemctl daemon-reload
  fi

  activate_client_configs "$candidate_wss" "$candidate_quic" "$candidate_shadow"

  echo
  echo '============================================================'
  echo ' shah1-v5 CLIENT READY'
  echo " Server       : ${server_addr}"
  echo " WSS control  : ${server_port}/tcp"
  echo " QUIC control : ${quic_port}/udp"
  echo " Local        : 127.0.0.1:${local_port}"
  echo " Remote       : ${remote_port}/tcp"
  echo ' Wire         : v2'
  echo ' Failover     : WSS (WebSocket+TLS) -> QUIC -> ShadowTLS-v3 (optional)'
  if [[ "$shadow_enabled" == 'yes' ]]; then
    echo " Shadow local : 127.0.0.1:${DEFAULT_SHADOW_LOCAL}"
    echo " Shadow SNI   : $(cat "$SHADOW_SNI_FILE")"
  else
    echo ' ShadowTLS    : OFF'
  fi
  echo ' Verify       : PASSED BEFORE ACTIVATION'
  echo '============================================================'
  echo

  if port_listening_tcp "$local_port"; then
    log "Local backend 127.0.0.1:${local_port} is listening."
  else
    log "WARNING: 127.0.0.1:${local_port} is not currently listening; client tunnel is installed but backend may be down."
  fi

  trap - RETURN
  rm -rf "$tmp" "$candidate_wss" "$candidate_quic"
  [[ -z "$candidate_shadow" ]] || rm -f "$candidate_shadow"
}

status_mode(){
  echo '--- shah1-v5 server ---'
  systemctl --no-pager --full status "$SERVER_UNIT" 2>/dev/null || true
  echo
  echo '--- shah1-v5 client ---'
  systemctl --no-pager --full status "$CLIENT_UNIT" 2>/dev/null || true
  echo
  echo '--- ShadowTLS server ---'
  systemctl --no-pager --full status "$SHADOW_SERVER_UNIT" 2>/dev/null || true
  echo
  echo '--- ShadowTLS client ---'
  systemctl --no-pager --full status "$SHADOW_CLIENT_UNIT" 2>/dev/null || true
  echo
  echo '--- FRP processes ---'
  pgrep -af 'shah1-v5|frps|frpc|shadow-tls' || true
  echo
  echo '--- listeners ---'
  ss -lntup | grep -E ':29064|:29065|:29443|:29444|:1740[1-3]|:443' || true
}

verify_mode(){
  local found=0
  if [[ -x "${BIN_DIR}/frps" && -f "$SERVER_CONF" ]]; then
    echo '--- frps verify ---'
    if "${BIN_DIR}/frps" verify -c "$SERVER_CONF"; then
      echo 'frps configuration: OK'
    else
      echo 'frps configuration: FAILED'
      found=1
    fi
  fi

  for cfg in "$CLIENT_WSS_CONF" "$CLIENT_QUIC_CONF" "$CLIENT_SHADOW_CONF"; do
    if [[ -x "${BIN_DIR}/frpc" && -f "$cfg" ]]; then
      echo "--- frpc verify: ${cfg##*/} ---"
      if "${BIN_DIR}/frpc" verify -c "$cfg"; then
        echo 'OK'
      else
        echo 'FAILED'
        found=1
      fi
    fi
  done

  if [[ -x "${BIN_DIR}/shadow-tls" ]]; then
    echo '--- ShadowTLS binary ---'
    "${BIN_DIR}/shadow-tls" --version || true
  fi

  [[ "$found" -eq 0 ]] || return 1
  echo 'All present shah1-v5 configurations passed verification.'
}

remove_mode(){
  echo 'This removes shah1-v5 only.'
  echo 'It does NOT remove user panels, Xray, or unrelated services.'
  read -r -p 'Type REMOVE to continue: ' confirm
  [[ "$confirm" == 'REMOVE' ]] || { echo 'Cancelled.'; return 0; }

  systemctl disable --now "$CLIENT_UNIT" "$SERVER_UNIT" "$SHADOW_CLIENT_UNIT" "$SHADOW_SERVER_UNIT" 2>/dev/null || true
  rm -f \
    "/etc/systemd/system/${CLIENT_UNIT}" \
    "/etc/systemd/system/${SERVER_UNIT}" \
    "/etc/systemd/system/${SHADOW_CLIENT_UNIT}" \
    "/etc/systemd/system/${SHADOW_SERVER_UNIT}"
  rm -rf "$ETC_DIR" "$BASE_DIR"
  systemctl daemon-reload
  systemctl reset-failed

  echo 'shah1-v5 removed.'
}

restart_mode(){
  local restarted=0
  for unit in "$SERVER_UNIT" "$SHADOW_SERVER_UNIT" "$SHADOW_CLIENT_UNIT" "$CLIENT_UNIT"; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1 && [[ -f "/etc/systemd/system/${unit}" ]]; then
      systemctl restart "$unit"
      restarted=1
    fi
  done
  if [[ "$restarted" -eq 0 ]]; then
    echo 'No shah1-v5 service is installed.'
  else
    echo 'shah1-v5 service restart requested.'
  fi
}

menu(){
  while true; do
    clear || true
    echo '==============================================='
    echo '         shah1-v5 ADVANCED FRP SETUP'
    echo '==============================================='
    echo '[1] 🇮🇷 Install / configure IRAN server'
    echo '[2] 🌐 Install / configure OUTSIDE client'
    echo '[3] 📊 Status'
    echo '[4] 🗑️  Remove shah1-v5 only'
    echo '[5] ✅ Verify configuration'
    echo '[6] 🚪 Exit'
    echo '==============================================='
    read -r -p 'Choose [1-6]: ' choice
    echo

    case "$choice" in
      1) server_mode || true; read -r -p 'Press Enter to continue... ' _ ;;
      2) client_mode || true; read -r -p 'Press Enter to continue... ' _ ;;
      3) status_mode || true; read -r -p 'Press Enter to continue... ' _ ;;
      4) remove_mode || true; read -r -p 'Press Enter to continue... ' _ ;;
      5) verify_mode || true; read -r -p 'Press Enter to continue... ' _ ;;
      6) exit 0 ;;
      *) echo 'Invalid choice.'; sleep 1 ;;
    esac
  done
}

main(){
  need_root
  require_cmd systemctl
  require_cmd ss
  require_cmd openssl
  require_cmd timeout

  if [[ $# -eq 0 ]]; then
    menu
    return
  fi

  case "$1" in
    server) server_mode ;;
    client) client_mode ;;
    status) status_mode ;;
    verify) verify_mode ;;
    restart) restart_mode ;;
    remove) remove_mode ;;
    menu) menu ;;
    *)
      echo 'Usage:'
      echo '  bash shah1.sh            # open menu'
      echo '  bash shah1.sh server'
      echo '  bash shah1.sh client'
      echo '  bash shah1.sh status'
      echo '  bash shah1.sh verify'
      echo '  bash shah1.sh restart'
      echo '  bash shah1.sh remove'
      exit 1
      ;;
  esac
}

main "$@"
