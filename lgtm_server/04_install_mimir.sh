#!/bin/bash
set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"

VERSION="3.0.5"

if [ -f "$BIN_DIR/mimir" ]; then
    echo "[INFO] Mimir already installed ✔"
else
    echo "[INFO] Downloading Mimir..."

    cd /tmp
    wget --show-progress https://github.com/grafana/mimir/releases/download/mimir-${VERSION}/mimir_${VERSION}_linux_amd64.tar.gz

    tar -xzf mimir_${VERSION}_linux_amd64.tar.gz

    mv mimir_${VERSION}_linux_amd64/mimir $BIN_DIR/mimir
    chmod +x $BIN_DIR/mimir
fi