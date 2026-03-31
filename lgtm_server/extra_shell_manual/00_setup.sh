#!/bin/bash

set -e

BASE_DIR="/opt/lgtm"

echo "[INFO] Creating base directories..."

sudo mkdir -p $BASE_DIR/{bin,config,data}
sudo mkdir -p $BASE_DIR/data/{loki,tempo,mimir,prometheus}

sudo chown -R $USER:$USER $BASE_DIR

echo "[INFO] Installing dependencies..."
sudo apt update -y
sudo apt install -y wget unzip tar curl

echo "[INFO] Setup completed ✔"