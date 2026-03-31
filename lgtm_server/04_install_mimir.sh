#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

if [ -f "$BIN_DIR/mimir" ]; then
    echo "[INFO] Mimir already installed ✔"
else
    echo "[INFO] Downloading Mimir..."
    cd /tmp
    wget --show-progress https://github.com/grafana/mimir/releases/latest/download/mimir-linux-amd64.zip
    unzip mimir-linux-amd64.zip
    mv mimir-linux-amd64 $BIN_DIR/mimir
    chmod +x $BIN_DIR/mimir
fi

echo "[INFO] Creating Mimir config..."

cat <<EOF > $CONFIG_DIR/mimir.yaml
server:
  http_listen_port: 9009

storage:
  backend: filesystem
  filesystem:
    dir: $DATA_DIR/mimir
EOF

echo "[INFO] Creating Mimir service..."

sudo bash -c "cat > /etc/systemd/system/mimir.service" <<EOF
[Unit]
Description=Mimir
After=network.target

[Service]
ExecStart=$BIN_DIR/mimir -config.file=$CONFIG_DIR/mimir.yaml
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mimir
sudo systemctl restart mimir

echo "[INFO] Mimir running at http://<EC2-IP>:9009"