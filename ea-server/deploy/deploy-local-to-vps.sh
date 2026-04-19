#!/bin/bash
# Deploy local ea-server binary to VPS systemd install
# Usage:
#   sudo bash deploy-local-to-vps.sh /path/to/ea-server

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: sudo bash $0 /path/to/ea-server"
  exit 1
fi

BINARY_PATH="$1"
INSTALL_DIR="/opt/ea-24"
SERVICE_NAME="ea-server"

if [ ! -f "$BINARY_PATH" ]; then
  echo "Binary not found: $BINARY_PATH"
  exit 1
fi

echo "Stopping ${SERVICE_NAME}..."
systemctl stop "${SERVICE_NAME}" || true

echo "Creating install dir ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"

echo "Copying binary..."
cp "$BINARY_PATH" "${INSTALL_DIR}/ea-server"
chmod +x "${INSTALL_DIR}/ea-server"

echo "Installing service file..."
cp "$(dirname "$0")/ea-server.service" "/etc/systemd/system/${SERVICE_NAME}.service"

echo "Reloading systemd..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo "Done. Service status:"
systemctl status "${SERVICE_NAME}" --no-pager
