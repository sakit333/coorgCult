#!/bin/bash
set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

VERSION="2.10.3"

mkdir -p $BIN_DIR $CONFIG_DIR $DATA_DIR

if [ -f "$BIN_DIR/tempo" ]; then
    echo "[INFO] Tempo already installed ✔"
else
    echo "[INFO] Downloading Tempo..."

    cd /tmp
    rm -rf tempo*

    wget --show-progress https://github.com/grafana/tempo/releases/download/v${VERSION}/tempo_${VERSION}_linux_amd64.tar.gz

    echo "[INFO] Extracting..."
    tar -xzf tempo_${VERSION}_linux_amd64.tar.gz

    echo "[INFO] Locating tempo binary..."

    TEMPO_BIN=$(find /tmp -type f -name "tempo" | head -n 1)

    if [ -z "$TEMPO_BIN" ]; then
        echo "❌ ERROR: tempo binary not found!"
        exit 1
    fi

    echo "[INFO] Found: $TEMPO_BIN"

    mv "$TEMPO_BIN" $BIN_DIR/tempo
    chmod +x $BIN_DIR/tempo

    echo "[INFO] Tempo installed ✔"
fi

# CONFIG
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

# SERVICE
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

echo "[INFO] Tempo started on port 3200 ✔"