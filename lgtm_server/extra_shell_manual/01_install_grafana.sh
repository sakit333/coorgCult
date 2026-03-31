#!/bin/bash

set -e

if command -v grafana-server &> /dev/null; then
    echo "[INFO] Grafana already installed ✔"
    exit 0
fi

echo "[INFO] Installing Grafana..."

sudo apt-get install -y software-properties-common

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update -y
sudo apt install -y grafana

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "[INFO] Grafana started at http://<EC2-IP>:3000"