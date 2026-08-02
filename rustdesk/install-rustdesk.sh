#!/usr/bin/env bash
#
# install-rustdesk.sh — Native install of RustDesk server (hbbs + hbbr) via systemd.
# No Docker. Runs as a dedicated unprivileged user. Everything lives under a few
# well-known paths so uninstall-rustdesk.sh can remove it cleanly.
#
# Usage:
#   sudo ./install-rustdesk.sh [PUBLIC_IP]
#
# If PUBLIC_IP is omitted, the script auto-detects it via ifconfig.me.

set -euo pipefail

# ---- layout (keep in sync with uninstall-rustdesk.sh) ----------------------
RD_USER="rustdesk"
RD_BIN_DIR="/opt/rustdesk/bin"
RD_DATA_DIR="/var/lib/rustdesk"
RD_LOG_DIR="/var/log/rustdesk"
SYSTEMD_DIR="/etc/systemd/system"
GITHUB_REPO="rustdesk/rustdesk-server"

# ---- must be root -----------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "Run this as root (sudo ./install-rustdesk.sh)." >&2
  exit 1
fi

# ---- detect public IP --------------------------------------------------------
PUBLIC_IP="${1:-}"
if [[ -z "$PUBLIC_IP" ]]; then
  echo "==> Detecting public IP..."
  PUBLIC_IP="$(curl -fsSL https://ifconfig.me || curl -fsSL https://api.ipify.org)"
fi
echo "==> Using public IP: $PUBLIC_IP"

# ---- detect arch --------------------------------------------------------------
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64)  RD_ARCH="amd64" ;;
  aarch64) RD_ARCH="arm64v8" ;;
  armv7l)  RD_ARCH="armv7" ;;
  *) echo "Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac
echo "==> Detected arch: $ARCH_RAW -> package suffix: $RD_ARCH"

# ---- fetch latest release tag ------------------------------------------------
echo "==> Looking up latest rustdesk-server release..."
RELEASE_JSON="$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")"
LATEST_TAG="$(printf '%s\n' "$RELEASE_JSON" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
if [[ -z "$LATEST_TAG" ]]; then
  echo "Could not resolve latest release tag." >&2
  exit 1
fi
echo "==> Latest version: $LATEST_TAG"

ASSET="rustdesk-server-linux-${RD_ARCH}.zip"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}/${ASSET}"

# ---- create dedicated user (no login, no home shell) -------------------------
if ! id -u "$RD_USER" &>/dev/null; then
  echo "==> Creating system user '$RD_USER'..."
  useradd --system --no-create-home --shell /usr/sbin/nologin "$RD_USER"
fi

# ---- prepare directories -------------------------------------------------------
echo "==> Creating directories..."
mkdir -p "$RD_BIN_DIR" "$RD_DATA_DIR" "$RD_LOG_DIR"
chown -R "$RD_USER:$RD_USER" "$RD_DATA_DIR" "$RD_LOG_DIR"

# ---- download + install binaries ----------------------------------------------
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Downloading $ASSET..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/rustdesk-server.zip"

echo "==> Extracting..."
if ! command -v unzip &>/dev/null; then
  apt-get update -y && apt-get install -y unzip
fi
unzip -q "$TMP_DIR/rustdesk-server.zip" -d "$TMP_DIR"

FOUND_HBBS="$(find "$TMP_DIR" -type f -name hbbs | head -n1)"
FOUND_HBBR="$(find "$TMP_DIR" -type f -name hbbr | head -n1)"
if [[ -z "$FOUND_HBBS" || -z "$FOUND_HBBR" ]]; then
  echo "hbbs/hbbr binaries not found in release archive." >&2
  exit 1
fi

install -m 0755 -o root -g root "$FOUND_HBBS" "$RD_BIN_DIR/hbbs"
install -m 0755 -o root -g root "$FOUND_HBBR" "$RD_BIN_DIR/hbbr"

# ---- systemd units ---------------------------------------------------------------
echo "==> Writing systemd unit files..."

cat > "$SYSTEMD_DIR/rustdesk-hbbs.service" <<EOF
[Unit]
Description=RustDesk ID/Rendezvous Server (hbbs)
After=network.target
Requires=rustdesk-hbbr.service

[Service]
Type=simple
User=${RD_USER}
Group=${RD_USER}
WorkingDirectory=${RD_DATA_DIR}
ExecStart=${RD_BIN_DIR}/hbbs -r ${PUBLIC_IP}:21117
Restart=on-failure
RestartSec=5
StandardOutput=append:${RD_LOG_DIR}/hbbs.log
StandardError=append:${RD_LOG_DIR}/hbbs.log

# light hardening
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${RD_DATA_DIR} ${RD_LOG_DIR}
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

cat > "$SYSTEMD_DIR/rustdesk-hbbr.service" <<EOF
[Unit]
Description=RustDesk Relay Server (hbbr)
After=network.target

[Service]
Type=simple
User=${RD_USER}
Group=${RD_USER}
WorkingDirectory=${RD_DATA_DIR}
ExecStart=${RD_BIN_DIR}/hbbr
Restart=on-failure
RestartSec=5
StandardOutput=append:${RD_LOG_DIR}/hbbr.log
StandardError=append:${RD_LOG_DIR}/hbbr.log

NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${RD_DATA_DIR} ${RD_LOG_DIR}
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# ---- firewall ----------------------------------------------------------------------
echo "==> Opening firewall ports (21115-21119 tcp, 21116 udp) if ufw is active..."
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 21115:21119/tcp
  ufw allow 21116/udp
else
  echo "    ufw not active/installed — open 21115-21119/tcp and 21116/udp manually (VPS provider firewall too)."
fi

# ---- enable + start ------------------------------------------------------------------
echo "==> Enabling and starting services..."
systemctl daemon-reload
systemctl enable --now rustdesk-hbbr.service
systemctl enable --now rustdesk-hbbs.service

sleep 2
echo ""
echo "==================================================================="
echo " RustDesk server installed."
echo " Public IP / Server ID (for client config): $PUBLIC_IP"
echo ""
echo " Public key for client (Key field in RustDesk client settings):"
if [[ -f "${RD_DATA_DIR}/id_ed25519.pub" ]]; then
  cat "${RD_DATA_DIR}/id_ed25519.pub"
else
  echo "   (not generated yet — check: cat ${RD_DATA_DIR}/id_ed25519.pub)"
fi
echo ""
echo " Manage:"
echo "   systemctl status rustdesk-hbbs rustdesk-hbbr"
echo "   journalctl -u rustdesk-hbbs -f    # or tail -f ${RD_LOG_DIR}/hbbs.log"
echo "   systemctl restart rustdesk-hbbs rustdesk-hbbr"
echo ""
echo " Remove cleanly:"
echo "   sudo ./uninstall-rustdesk.sh"
echo "==================================================================="
