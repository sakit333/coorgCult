#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

log() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }

# -------------------------
# SETUP DIRS
# -------------------------
setup_dirs() {
    log "Creating directories..."
    sudo mkdir -p $BIN_DIR $CONFIG_DIR $DATA_DIR/{loki,tempo,mimir,prometheus}
    sudo chown -R $USER:$USER $BASE_DIR
}

# -------------------------
# INSTALL DEPENDENCIES
# -------------------------
install_deps() {
    log "Installing dependencies..."
    sudo apt update -y
    sudo apt install -y wget unzip tar curl
}

# -------------------------
# INSTALL GRAFANA
# -------------------------
install_grafana() {
    if command -v grafana-server &> /dev/null; then
        log "Grafana already installed ✔"
        return
    fi

    log "Installing Grafana..."

    sudo apt-get install -y software-properties-common
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

    sudo apt update -y
    sudo apt install -y grafana

    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
}

# -------------------------
# GENERIC DOWNLOAD FIXED
# -------------------------
download_and_prepare() {
    NAME=$1
    URL=$2
    TYPE=$3   # zip or tar

    if [ -f "$BIN_DIR/$NAME" ]; then
        log "$NAME already exists ✔"
        return
    fi

    log "Downloading $NAME..."

    TMP_FILE="/tmp/${NAME}_download"
    rm -rf /tmp/${NAME}*

    if [ "$TYPE" == "zip" ]; then
        wget -qO ${TMP_FILE}.zip $URL
        unzip -q ${TMP_FILE}.zip -d /tmp/
    else
        wget -qO ${TMP_FILE}.tar.gz $URL
        tar -xzf ${TMP_FILE}.tar.gz -C /tmp/
    fi

    # 🔥 FIND ACTUAL BINARY
    BIN_PATH=$(find /tmp -type f -name "${NAME}*" | head -n 1)

    if [ -z "$BIN_PATH" ]; then
        echo "❌ Failed to find binary for $NAME"
        exit 1
    fi

    mv "$BIN_PATH" "$BIN_DIR/$NAME"
    chmod +x "$BIN_DIR/$NAME"

    log "$NAME installed ✔"
}

# -------------------------
# CREATE SERVICE
# -------------------------
create_service() {
    NAME=$1
    CMD=$2

    if systemctl list-units --full -all | grep -q "$NAME.service"; then
        log "$NAME service already exists ✔"
        return
    fi

    log "Creating service: $NAME"

    sudo bash -c "cat > /etc/systemd/system/$NAME.service" <<EOF
[Unit]
Description=$NAME
After=network.target

[Service]
ExecStart=$CMD
Restart=always
User=$USER
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable $NAME
    sudo systemctl start $NAME
}

# -------------------------
# LOKI
# -------------------------
install_loki() {
    download_and_prepare "loki" \
    "https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip" zip

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

    create_service "loki" "$BIN_DIR/loki -config.file=$CONFIG_DIR/loki.yaml"
}

# -------------------------
# TEMPO
# -------------------------
install_tempo() {
    download_and_prepare "tempo" \
    "https://github.com/grafana/tempo/releases/latest/download/tempo-linux-amd64.zip" zip

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

    create_service "tempo" "$BIN_DIR/tempo -config.file=$CONFIG_DIR/tempo.yaml"
}

# -------------------------
# MIMIR
# -------------------------
install_mimir() {
    download_and_prepare "mimir" \
    "https://github.com/grafana/mimir/releases/latest/download/mimir-linux-amd64.zip" zip

    cat <<EOF > $CONFIG_DIR/mimir.yaml
server:
  http_listen_port: 9009

storage:
  backend: filesystem
  filesystem:
    dir: $DATA_DIR/mimir
EOF

    create_service "mimir" "$BIN_DIR/mimir -config.file=$CONFIG_DIR/mimir.yaml"
}

# -------------------------
# PROMETHEUS
# -------------------------
install_prometheus() {
    download_and_prepare "prometheus" \
    "https://github.com/prometheus/prometheus/releases/latest/download/prometheus-linux-amd64.tar.gz" tar

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

    create_service "prometheus" "$BIN_DIR/prometheus --config.file=$CONFIG_DIR/prometheus.yml --storage.tsdb.path=$DATA_DIR/prometheus"
}

# -------------------------
# MAIN
# -------------------------
main() {
    setup_dirs
    install_deps
    install_grafana
    install_loki
    install_tempo
    install_mimir
    install_prometheus

    echo ""
    echo "🎉 LGTM + PROMETHEUS READY!"
    echo "Grafana → http://<EC2-IP>:3000"
}

main