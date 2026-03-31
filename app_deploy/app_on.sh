#!/bin/bash

set -e

PROJECT_DIR="/home/ubuntu/coorgCult"
REPO_URL="https://github.com/sakit333/coorgCult.git"
COMPOSE_FILE="app_deploy/docker-compose.dev.yml"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------
# INSTALL DOCKER (IF NOT EXISTS)
# -----------------------------
install_docker() {
  if command -v docker &> /dev/null; then
    log "Docker already installed ✔"
  else
    log "Installing Docker..."

    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo usermod -aG docker $USER

    warn "Run: newgrp docker OR relogin"
  fi
}

# -----------------------------
# SETUP PROJECT
# -----------------------------
setup_project() {
  if [ -d "$PROJECT_DIR" ]; then
    log "Project exists. Pulling latest..."
    cd $PROJECT_DIR
    git pull origin main
  else
    log "Cloning repo..."
    git clone $REPO_URL $PROJECT_DIR
    cd $PROJECT_DIR
  fi
}

# -----------------------------
# ENV SETUP (INTERACTIVE)
# -----------------------------
setup_env() {
  cd $PROJECT_DIR

  echo "Select environment:"
  echo "1. Docker (.env.docker)"
  echo "2. Local (.env.local)"

  read -p "Choice [1/2]: " choice

  if [ "$choice" == "2" ]; then
    if [ -f "app_deploy/.env.local" ]; then
      cp app_deploy/.env.local .env
      log "Using LOCAL env ✔"
    else
      error ".env.local not found in app_deploy/"
      exit 1
    fi
  else
    if [ -f "app_deploy/.env.docker" ]; then
      cp app_deploy/.env.docker .env
      log "Using DOCKER env ✔"
    else
      error ".env.docker not found in app_deploy/"
      exit 1
    fi
  fi
}

# -----------------------------
# DEPLOY
# -----------------------------
deploy() {
  install_docker
  setup_project
  setup_env

  cd $PROJECT_DIR

  MAX_RETRIES=3
  COUNT=1

  while [ $COUNT -le $MAX_RETRIES ]; do
    log "🚀 Deployment attempt $COUNT..."

    # Stop old containers
    docker compose -f $COMPOSE_FILE down || true

    # Build & start
    if docker compose -f $COMPOSE_FILE up -d --build; then
      log "✅ Deployment successful!"
      return 0
    fi

    warn "❌ Deployment failed (attempt $COUNT)"

    echo "🔧 Cleaning up before retry..."

    # Cleanup containers
    docker compose -f $COMPOSE_FILE down -v || true

    # Remove dangling images
    docker system prune -f

    # Remove failed images
    docker image prune -f

    COUNT=$((COUNT+1))

    if [ $COUNT -le $MAX_RETRIES ]; then
      warn "🔁 Retrying deployment..."
      sleep 5
    fi
  done

  error "🔥 Deployment failed after $MAX_RETRIES attempts!"
  exit 1
}

# -----------------------------
# STOP
# -----------------------------
stop_app() {
  cd $PROJECT_DIR
  docker compose -f $COMPOSE_FILE down
}

# -----------------------------
# RESTART
# -----------------------------
restart_app() {
  cd $PROJECT_DIR
  docker compose -f $COMPOSE_FILE down
  docker compose -f $COMPOSE_FILE up -d --build
}

# -----------------------------
# LOGS
# -----------------------------
view_logs() {
  cd $PROJECT_DIR
  docker compose -f $COMPOSE_FILE logs -f
}

# -----------------------------
# REMOVE EVERYTHING
# -----------------------------
remove_all() {
  warn "⚠️ This will DELETE everything!"

  read -p "Type 'DELETE' to confirm: " confirm

  if [[ "$confirm" != "DELETE" ]]; then
    log "Cancelled"
    exit 0
  fi

  cd $PROJECT_DIR

  docker compose -f $COMPOSE_FILE down -v

  cd ~
  rm -rf $PROJECT_DIR

  docker system prune -a -f --volumes

  log "🔥 removed!"
}

# add force clean action
force_clean_deploy() {
  cd $PROJECT_DIR

  warn "⚠️ Full cleanup before deploy..."

  docker compose -f $COMPOSE_FILE down -v || true
  docker system prune -a -f --volumes

  deploy
}

# -----------------------------
# MENU
# -----------------------------
while true; do
  echo ""
  echo "========= MENU ========="
  echo "1. Deploy Application"
  echo "2. Stop Application"
  echo "3. Restart Application"
  echo "4. View Logs"
  echo "5. Remove Everything"
  echo "6. Force Clean Deploy"
  echo "7. Status"
  echo "8. Exit"  
  echo "========================"

  read -p "Choose option: " choice

  case $choice in
    1) deploy ;;
    2) stop_app ;;
    3) restart_app ;;
    4) view_logs ;;
    5) remove_all ;;
    6) force_clean_deploy ;;
    7) docker ps ;;
    8) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
done