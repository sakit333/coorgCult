#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

if [ -f "$BIN_DIR/loki" ]; then
    echo "[INFO] Loki already installed ✔"
else
    echo "[INFO] Downloading Loki..."
    cd /tmp
    wget --show-progress https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip
    unzip loki-linux-amd64.zip
    mv loki-linux-amd64 $BIN_DIR/loki
    chmod +x $BIN_DIR/loki
fi

echo "[INFO] Creating Loki config..."

cat <<EOF > $CONFIG_DIR/loki.yaml
auth_enabled: false
server:
  http_listen_port: 3100

storage_config:
  boltdb_shipper:
    active_index_directory: $DATA_DIR/loki/index
    cache_location: $DATA_DIR/loki/cache
  filesystem:
    directory: $DATA_DIR/loki/chunks

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF

echo "[INFO] Creating Loki service..."

sudo bash -c "cat > /etc/systemd/system/loki.service" <<EOF
[Unit]
Description=Loki
After=network.target

[Service]
ExecStart=$BIN_DIR/loki -config.file=$CONFIG_DIR/loki.yaml
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl restart loki

echo "[INFO] Loki running at http://<EC2-IP>:3100"