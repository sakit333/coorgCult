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

    # ✅ Correct file (UPDATED)
    wget --show-progress https://github.com/grafana/tempo/releases/latest/download/tempo-linux-amd64.tar.gz

    echo "[INFO] Extracting Tempo..."
    tar -xzf tempo-linux-amd64.tar.gz

    # 🔍 Find correct binary
    TEMPO_BIN=$(find /tmp -type f -name "tempo" | head -n 1)

    if [ -z "$TEMPO_BIN" ]; then
        echo "❌ Tempo binary not found!"
        exit 1
    fi

    mv "$TEMPO_BIN" $BIN_DIR/tempo
    chmod +x $BIN_DIR/tempo

    echo "[INFO] Tempo installed ✔"
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