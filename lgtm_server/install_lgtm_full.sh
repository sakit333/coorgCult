#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

log() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }

# -------------------------
# SETUP DIRECTORIES
# -------------------------
setup_dirs() {
    log "Creating directories..."
    sudo mkdir -p $BIN_DIR $CONFIG_DIR $DATA_DIR/{loki,tempo,mimir,prometheus}
    sudo chown -R $USER:$USER $BASE_DIR
}

# -------------------------
# INSTALL DOCKER (optional)
# -------------------------
install_dependencies() {
    log "Installing dependencies..."
    sudo apt update -y
    sudo apt install -y wget unzip curl
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

    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
}

# -------------------------
# DOWNLOAD BINARIES
# -------------------------
download_binary() {
    NAME=$1
    URL=$2

    if [ -f "$BIN_DIR/$NAME" ]; then
        log "$NAME already exists ✔"
        return
    fi

    log "Downloading $NAME..."
    wget -qO /tmp/$NAME.zip $URL
    unzip -q /tmp/$NAME.zip -d /tmp/
    mv /tmp/$NAME*/$NAME $BIN_DIR/
    chmod +x $BIN_DIR/$NAME
}

# -------------------------
# CREATE SERVICE
# -------------------------
create_service() {
    NAME=$1
    CMD=$2

    if systemctl list-units --full -all | grep -q "$NAME.service"; then
        log "$NAME already exists ✔"
        return
    fi

    log "Creating service for $NAME..."

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
    download_binary "loki" "https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip"

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
    download_binary "tempo" "https://github.com/grafana/tempo/releases/latest/download/tempo-linux-amd64.zip"

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
    download_binary "mimir" "https://github.com/grafana/mimir/releases/latest/download/mimir-linux-amd64.zip"

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
    download_binary "prometheus" "https://github.com/prometheus/prometheus/releases/latest/download/prometheus-linux-amd64.tar.gz"

    if [ ! -f "$BIN_DIR/prometheus" ]; then
        tar -xzf /tmp/prometheus-linux-amd64.tar.gz -C /tmp/
        mv /tmp/prometheus-*/prometheus $BIN_DIR/
        chmod +x $BIN_DIR/prometheus
    fi

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
# STATUS
# -------------------------
status() {
    echo ""
    echo "===== SERVICES ====="
    systemctl status grafana-server --no-pager | head -3
    systemctl status loki --no-pager | head -3
    systemctl status tempo --no-pager | head -3
    systemctl status mimir --no-pager | head -3
    systemctl status prometheus --no-pager | head -3
}

# -------------------------
# MAIN
# -------------------------
main() {
    setup_dirs
    install_dependencies
    install_grafana
    install_loki
    install_tempo
    install_mimir
    install_prometheus
    status

    echo ""
    echo "🎉 FULL LGTM STACK READY!"
    echo "Grafana    → http://<EC2-IP>:3000"
    echo "Loki       → http://<EC2-IP>:3100"
    echo "Tempo      → http://<EC2-IP>:3200"
    echo "Mimir      → http://<EC2-IP>:9009"
    echo "Prometheus → http://<EC2-IP>:9090"
}

main