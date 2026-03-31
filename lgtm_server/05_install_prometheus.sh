#!/bin/bash
set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

VERSION="2.51.2"

mkdir -p $BIN_DIR $CONFIG_DIR $DATA_DIR

if [ -f "$BIN_DIR/prometheus" ]; then
    echo "[INFO] Prometheus already installed ✔"
else
    echo "[INFO] Downloading Prometheus..."

    cd /tmp
    rm -rf prometheus*

    wget --show-progress https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz

    echo "[INFO] Extracting..."
    tar -xzf prometheus-${VERSION}.linux-amd64.tar.gz

    echo "[INFO] Locating Prometheus binary..."

    PROM_BIN=$(find /tmp -type f -name "prometheus" | grep linux | head -n 1)

    if [ -z "$PROM_BIN" ]; then
        echo "❌ Prometheus binary not found!"
        exit 1
    fi

    echo "[INFO] Found: $PROM_BIN"

    mv "$PROM_BIN" $BIN_DIR/prometheus
    chmod +x $BIN_DIR/prometheus

    # Move default tools too (optional but useful)
    cp -r /tmp/prometheus-${VERSION}.linux-amd64/consoles $CONFIG_DIR/
    cp -r /tmp/prometheus-${VERSION}.linux-amd64/console_libraries $CONFIG_DIR/

    echo "[INFO] Prometheus installed ✔"
fi

echo "[INFO] Creating Prometheus config..."

cat <<EOF > $CONFIG_DIR/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

echo "[INFO] Creating systemd service..."

sudo bash -c "cat > /etc/systemd/system/prometheus.service" <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
ExecStart=$BIN_DIR/prometheus \
  --config.file=$CONFIG_DIR/prometheus.yml \
  --storage.tsdb.path=$DATA_DIR/prometheus

Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

echo "[INFO] Prometheus running on http://<EC2-IP>:9090 ✔"