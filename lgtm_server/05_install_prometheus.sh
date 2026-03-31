#!/bin/bash
set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"

VERSION="2.51.2"

if [ -f "$BIN_DIR/prometheus" ]; then
    echo "[INFO] Prometheus already installed ✔"
else
    echo "[INFO] Downloading Prometheus..."

    cd /tmp
    wget --show-progress https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz

    tar -xzf prometheus-${VERSION}.linux-amd64.tar.gz

    mv prometheus-${VERSION}.linux-amd64/prometheus $BIN_DIR/prometheus
    chmod +x $BIN_DIR/prometheus
fi
