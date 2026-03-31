#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

if [ -f "$BIN_DIR/prometheus" ]; then
    echo "[INFO] Prometheus already installed ✔"
else
    echo "[INFO] Downloading Prometheus..."
    cd /tmp
    wget --show-progress https://github.com/prometheus/prometheus/releases/latest/download/prometheus-linux-amd64.tar.gz
    tar -xzf prometheus-linux-amd64.tar.gz
    mv prometheus-*/prometheus $BIN_DIR/prometheus
    chmod +x $BIN_DIR/prometheus
fi

echo "[INFO] Creating Prometheus config..."

cat <<EOF > $CONFIG_DIR/prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'fastapi'
    static_configs:
      - targets: ['localhost:8000']

remote_write:
  - url: http://localhost:9009/api/v1/push
EOF

echo "[INFO] Creating Prometheus service..."

sudo bash -c "cat > /etc/systemd/system/prometheus.service" <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
ExecStart=$BIN_DIR/prometheus --config.file=$CONFIG_DIR/prometheus.yml --storage.tsdb.path=$DATA_DIR/prometheus
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

echo "[INFO] Prometheus running at http://<EC2-IP>:9090"