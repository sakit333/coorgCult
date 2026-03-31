#!/bin/bash
set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

VERSION="2.10.3"

if [ -f "$BIN_DIR/tempo" ]; then
    echo "[INFO] Tempo already installed ✔"
else
    echo "[INFO] Downloading Tempo..."

    cd /tmp
    wget --show-progress https://github.com/grafana/tempo/releases/download/v${VERSION}/tempo_${VERSION}_linux_amd64.tar.gz

    tar -xzf tempo_${VERSION}_linux_amd64.tar.gz

    mv tempo_${VERSION}_linux_amd64/tempo $BIN_DIR/tempo
    chmod +x $BIN_DIR/tempo
fi

echo "[INFO] Starting Tempo..."
sudo systemctl restart tempo 2>/dev/null || true