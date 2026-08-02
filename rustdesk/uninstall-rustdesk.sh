#!/usr/bin/env bash
#
# uninstall-rustdesk.sh — Clean removal of the native RustDesk server install
# created by install-rustdesk.sh. Mirrors the exact same paths so nothing is
# left behind (and nothing outside those paths is touched).
#
# Usage:
#   sudo ./uninstall-rustdesk.sh          # removes everything, including keys/db
#   sudo ./uninstall-rustdesk.sh --keep-data   # keeps /var/lib/rustdesk (id keys, db)

set -euo pipefail

RD_USER="rustdesk"
RD_BIN_DIR="/opt/rustdesk/bin"
RD_DATA_DIR="/var/lib/rustdesk"
RD_LOG_DIR="/var/log/rustdesk"
SYSTEMD_DIR="/etc/systemd/system"

KEEP_DATA=false
if [[ "${1:-}" == "--keep-data" ]]; then
  KEEP_DATA=true
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run this as root (sudo ./uninstall-rustdesk.sh)." >&2
  exit 1
fi

echo "==> Stopping services..."
systemctl stop rustdesk-hbbs.service 2>/dev/null || true
systemctl stop rustdesk-hbbr.service 2>/dev/null || true

echo "==> Disabling services..."
systemctl disable rustdesk-hbbs.service 2>/dev/null || true
systemctl disable rustdesk-hbbr.service 2>/dev/null || true

echo "==> Removing systemd unit files..."
rm -f "${SYSTEMD_DIR}/rustdesk-hbbs.service" "${SYSTEMD_DIR}/rustdesk-hbbr.service"
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

echo "==> Removing binaries..."
rm -rf "/opt/rustdesk"

if $KEEP_DATA; then
  echo "==> Keeping data dir (per --keep-data): ${RD_DATA_DIR}"
else
  echo "==> Removing data dir: ${RD_DATA_DIR}"
  rm -rf "${RD_DATA_DIR}"
fi

echo "==> Removing logs: ${RD_LOG_DIR}"
rm -rf "${RD_LOG_DIR}"

if id -u "$RD_USER" &>/dev/null; then
  echo "==> Removing system user '$RD_USER'..."
  userdel "$RD_USER" 2>/dev/null || true
fi

echo "==> Removing firewall rules (ufw, if present)..."
if command -v ufw &>/dev/null; then
  ufw delete allow 21115:21119/tcp 2>/dev/null || true
  ufw delete allow 21116/udp 2>/dev/null || true
fi

echo ""
echo "RustDesk server removed."
if $KEEP_DATA; then
  echo "Data preserved at ${RD_DATA_DIR} (id keys / db) — delete manually if not needed."
fi
