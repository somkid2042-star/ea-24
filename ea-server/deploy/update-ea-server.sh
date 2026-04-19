#!/bin/bash
# Update EA-24 server on VPS from GitHub release or local binary
# Usage:
#   sudo bash update-ea-server.sh
#
# Optional env vars:
#   REPO=owner/repo
#   INSTALL_DIR=/opt/ea-24
#   SERVICE_NAME=ea-server
#   EA_SERVER_BINARY_URL=https://github.com/.../releases/download/.../ea-server
#   EA_SERVER_BINARY_PATH=/tmp/ea-server (local binary override)

set -euo pipefail

REPO="${REPO:-somkid2042-star/ea-24}"
INSTALL_DIR="${INSTALL_DIR:-/opt/ea-24}"
SERVICE_NAME="${SERVICE_NAME:-ea-server}"
BINARY_NAME="ea-server"

mkdir -p "${INSTALL_DIR}"

echo "Stopping ${SERVICE_NAME}..."
systemctl stop "${SERVICE_NAME}" || true

if [ -n "${EA_SERVER_BINARY_PATH:-}" ] && [ -f "${EA_SERVER_BINARY_PATH}" ]; then
  echo "Using local binary: ${EA_SERVER_BINARY_PATH}"
  cp "${EA_SERVER_BINARY_PATH}" "${INSTALL_DIR}/${BINARY_NAME}"
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
else
  if [ -z "${EA_SERVER_BINARY_URL:-}" ]; then
    echo "Resolving latest GitHub release tag for ${REPO}..."
    TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | python3 - <<'PY'
import json,sys
obj=json.load(sys.stdin)
print(obj.get("tag_name",""))
PY
)
    if [ -z "${TAG}" ]; then
      echo "Could not determine latest release tag. Set EA_SERVER_BINARY_URL manually."
      exit 1
    fi
    EA_SERVER_BINARY_URL="https://github.com/${REPO}/releases/download/${TAG}/${BINARY_NAME}"
  fi

  echo "Downloading ${EA_SERVER_BINARY_URL}..."
  tmp_file="$(mktemp)"
  curl -fL "${EA_SERVER_BINARY_URL}" -o "${tmp_file}"
  install -m 755 "${tmp_file}" "${INSTALL_DIR}/${BINARY_NAME}"
  rm -f "${tmp_file}"
fi

echo "Installing service file..."
install -m 644 "$(dirname "$0")/ea-server.service" "/etc/systemd/system/${SERVICE_NAME}.service"

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo "Done. Current status:"
systemctl --no-pager status "${SERVICE_NAME}"
