#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

if [ -f "$BIN_DIR/tempo" ]; then
    echo "[INFO] Tempo already installed ✔"
else
    echo "[INFO] Downloading Tempo..."
    cd /tmp
    wget --show-progress https://github.com/grafana/tempo/releases/latest/download/tempo-linux-amd64.zip
    unzip tempo-linux-amd64.zip
    mv tempo-linux-amd64 $BIN_DIR/tempo
    chmod +x $BIN_DIR/tempo
fi

echo "[INFO] Creating Tempo config..."

cat <<EOF > $CONFIG_DIR/tempo.yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        http:
        grpc:

storage:
  trace:
    backend: local
    local:
      path: $DATA_DIR/tempo
EOF

echo "[INFO] Creating Tempo service..."

sudo bash -c "cat > /etc/systemd/system/tempo.service" <<EOF
[Unit]
Description=Tempo
After=network.target

[Service]
ExecStart=$BIN_DIR/tempo -config.file=$CONFIG_DIR/tempo.yaml
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tempo
sudo systemctl restart tempo

echo "[INFO] Tempo running at http://<EC2-IP>:3200"