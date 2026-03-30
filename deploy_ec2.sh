#!/bin/bash

# ==============================================================================
# CoorgCult Production EC2 Setup Script (Ubuntu)
# ==============================================================================

set -e

echo "➡️ Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "➡️ Installing Git, curl, wget, and necessary security dependencies..."
sudo apt-get install -y git curl wget ufw apt-transport-https ca-certificates software-properties-common

echo "➡️ Installing Docker engine..."
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

# Install Docker components
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "➡️ Fixing Docker permissions..."
# Allow the default Ubuntu 'ubuntu' user to run docker commands without sudo
sudo usermod -aG docker $USER

echo "➡️ Installing Ollama (AI Engine)..."
# We install Ollama locally on the EC2 machine because connecting it straight to host GPUs/CPUs is generally easier than containerizing it
curl -fsSL https://ollama.com/install.sh | sh

echo "➡️ Setting up Firewall rules..."
# Allow SSH access
sudo ufw allow 22/tcp
# Allow FastAPI web traffic (Change to 80 or 443 if you put Nginx/Caddy in front later!)
sudo ufw allow 8000/tcp
# We do NOT allow 11434 externally, keep Ollama safe behind localhost!

# Uncomment the line below to immediately enforce the firewall (highly recommended, but user preference)
# sudo ufw --force enable

echo "========================================================================="
echo "✅ EC2 Server preparation complete!"
echo "⚠️ IMPORTANT: You must log out and log back in for Docker permissions to apply."
echo ""
echo "Next Steps:"
echo "  1. Run 'logout' and reconnect to the server."
echo "  2. Clone your project:  git clone <YOUR_GIT_URL> coorgcult"
echo "  3. CD into directory:   cd coorgcult"
echo "  4. Pull your model:     ollama run <YOUR_MODEL_NAME> (e.g. ollama run llama3)"
echo "  5. Spin up the cluster: docker compose up -d --build"
echo "========================================================================="
