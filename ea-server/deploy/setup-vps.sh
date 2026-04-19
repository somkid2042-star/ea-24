#!/bin/bash
# ─────────────────────────────────────────────────────────────
# EA-24 Server — Ubuntu 22.04 Setup Script
# Run on VPS: sudo bash setup-vps.sh
# ─────────────────────────────────────────────────────────────

set -e

REPO="somkid2042-star/ea-24"
INSTALL_DIR="/opt/ea-24"
SERVICE_NAME="ea-server"
BINARY_NAME="ea-server"

echo "🚀 EA-24 Server Setup for Ubuntu 22.04"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 1: Create install directory ──
echo "📁 Creating ${INSTALL_DIR}..."
mkdir -p ${INSTALL_DIR}

echo "📦 Installing Python Telethon globally for the background service..."
apt-get update -y
apt-get install -y python3-pip
pip3 install telethon --break-system-packages || pip3 install telethon

# ── Step 2: Download latest ea-server binary from GitHub Releases or local path ──
if systemctl is-active --quiet ${SERVICE_NAME}; then
    echo "🛑 Stopping ${SERVICE_NAME} before update..."
    systemctl stop ${SERVICE_NAME}
fi

if [ -n "${EA_SERVER_BINARY_PATH:-}" ] && [ -f "${EA_SERVER_BINARY_PATH}" ]; then
    echo "📦 Using local binary: ${EA_SERVER_BINARY_PATH}"
    cp "${EA_SERVER_BINARY_PATH}" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
else
    echo "📥 Downloading latest ea-server binary from GitHub Releases..."
    LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/tags" | grep '"name": "v' | head -n 1 | cut -d '"' -f 4)
    if [ -z "$LATEST_TAG" ]; then
        echo "❌ Could not determine latest tag. GitHub might be blocking the request."
        echo "   Try: https://github.com/${REPO}/releases/latest"
        exit 1
    fi
    LATEST_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${BINARY_NAME}"
    echo "   URL: ${LATEST_URL}"
    wget -O "${INSTALL_DIR}/${BINARY_NAME}" "${LATEST_URL}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
fi

echo "📥 Downloading Telegram Python Proxy Scripts..."
wget -O ${INSTALL_DIR}/telegram_downloader.py "https://raw.githubusercontent.com/${REPO}/main/ea-server/telegram_downloader.py"
wget -O ${INSTALL_DIR}/telegram_session.session "https://raw.githubusercontent.com/${REPO}/main/ea-server/telegram_session.session"

echo "✅ Downloaded to ${INSTALL_DIR}/${BINARY_NAME}"

# ── Step 3: Create .env file (if not exists) ──
if [ ! -f "${INSTALL_DIR}/.env" ]; then
    echo "📝 Creating .env file..."
    cat > ${INSTALL_DIR}/.env << 'EOF'
DATABASE_URL=postgresql://ea24:ea24password@localhost:5432/ea24
RUST_LOG=info
EOF
    echo "⚠️  Please edit ${INSTALL_DIR}/.env with your actual database URL"
fi

# ── Step 4: Install systemd service ──
echo "⚙️  Installing systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=EA-24 Trading Server
After=network.target postgresql.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/ea-server
Restart=on-failure
RestartSec=5
EnvironmentFile=${INSTALL_DIR}/.env

# Resource limits
LimitNOFILE=65535

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ea-server

[Install]
WantedBy=multi-user.target
EOF

# ── Step 5: Enable and start service ──
echo "🔧 Enabling and starting ${SERVICE_NAME}..."
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl start ${SERVICE_NAME}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ EA-24 Server installed successfully!"
echo ""
echo "   📍 Binary: ${INSTALL_DIR}/${BINARY_NAME}"
echo "   📍 Config: ${INSTALL_DIR}/.env"
echo "   📍 Service: ${SERVICE_NAME}"
echo ""
echo "   📋 Useful commands:"
echo "   sudo systemctl status ${SERVICE_NAME}    # Check status"
echo "   sudo systemctl restart ${SERVICE_NAME}   # Restart"
echo "   sudo journalctl -u ${SERVICE_NAME} -f    # View logs"
echo ""
echo "   🔄 Auto-update: Server checks GitHub every 2 hours"
echo "      for new versions and updates itself automatically!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
