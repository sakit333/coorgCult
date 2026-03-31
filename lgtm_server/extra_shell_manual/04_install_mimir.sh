#!/bin/bash
set -e

echo "[INFO] Checking Docker..."

if ! command -v docker &> /dev/null; then
    echo "[INFO] Installing Docker..."
    apt update
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
else
    echo "[INFO] Docker already installed ✔"
fi

echo "[INFO] Creating Mimir config..."

mkdir -p /opt/lgtm/mimir

cat <<EOF > /opt/lgtm/mimir/mimir.yaml
server:
  http_listen_port: 9009

blocks_storage:
  backend: filesystem
  filesystem:
    dir: /data/blocks

compactor:
  data_dir: /data/compactor

distributor:
  ring:
    kvstore:
      store: inmemory

ingester:
  ring:
    kvstore:
      store: inmemory
    replication_factor: 1

store_gateway:
  sharding_ring:
    kvstore:
      store: inmemory
EOF

echo "[INFO] Running Mimir container..."

docker rm -f mimir 2>/dev/null || true

docker run -d \
  --name mimir \
  -p 9009:9009 \
  -v /opt/lgtm/mimir:/etc/mimir \
  -v /opt/lgtm/mimir/data:/data \
  grafana/mimir:latest \
  -config.file=/etc/mimir/mimir.yaml

echo "[INFO] Mimir running at http://<EC2-IP>:9009 ✔"