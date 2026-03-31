#!/bin/bash

set -e

PROJECT_DIR="/root/coorgCult"
COMPOSE_FILE="app_deploy/docker-compose.dev.yml"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------
# INSTALL DOCKER (SAFE)
# -----------------------------
install_docker() {
  if command -v docker &> /dev/null; then
    log "Docker already installed ✔"
  else
    log "Installing Docker..."

    sudo apt update -y
    sudo apt install -y docker.io docker-compose

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo usermod -aG docker $USER

    warn "Run: newgrp docker (only first time)"
  fi
}

# -----------------------------
# SETUP ENV (FIXED)
# -----------------------------
setup_env() {
  log "Setting up environment..."

  cd $PROJECT_DIR || exit 1

  if [ -f "$PROJECT_DIR/app_deploy/.env.docker" ]; then
    cp "$PROJECT_DIR/app_deploy/.env.docker" "$PROJECT_DIR/.env"
    log ".env created ✔"
  else
    error ".env.docker not found!"
    exit 1
  fi

  # Verify
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    error ".env creation failed!"
    exit 1
  fi
}

# -----------------------------
# DEPLOY (FINAL FIXED)
# -----------------------------
deploy() {
  install_docker
  setup_env

  cd $PROJECT_DIR

  MAX_RETRIES=3
  COUNT=1

  while [ $COUNT -le $MAX_RETRIES ]; do
    log "🚀 Deployment attempt $COUNT..."

    # Stop old containers
    docker compose -f $COMPOSE_FILE down || true

    # 🔥 IMPORTANT FIX: --env-file
    if docker compose --env-file .env -f $COMPOSE_FILE up -d --build; then
      log "✅ Deployment successful!"
      return 0
    fi

    warn "❌ Failed attempt $COUNT"

    # Cleanup
    docker compose -f $COMPOSE_FILE down -v || true
    docker system prune -f

    COUNT=$((COUNT+1))
    sleep 5
  done

  error "🔥 Deployment failed after retries"
  exit 1
}

# -----------------------------
# STOP
# -----------------------------
stop_app() {
  cd $PROJECT_DIR
  docker compose --env-file .env -f $COMPOSE_FILE down
}

# -----------------------------
# RESTART
# -----------------------------
restart_app() {
  cd $PROJECT_DIR
  docker compose --env-file .env -f $COMPOSE_FILE down
  docker compose --env-file .env -f $COMPOSE_FILE up -d --build
}

# -----------------------------
# LOGS
# -----------------------------
logs() {
  cd $PROJECT_DIR
  docker compose --env-file .env -f $COMPOSE_FILE logs -f
}

# -----------------------------
# REMOVE EVERYTHING
# -----------------------------
remove_all() {
  warn "⚠️ This will remove EVERYTHING"
  read -p "Type DELETE to confirm: " confirm

  if [ "$confirm" != "DELETE" ]; then
    log "Cancelled"
    return
  fi

  cd $PROJECT_DIR

  docker compose --env-file .env -f $COMPOSE_FILE down -v
  docker system prune -a -f --volumes

  log "🔥 Fully cleaned"
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
  echo "6. Status"
  echo "7. Exit"
  echo "========================"

  read -p "Choose option: " choice

  case $choice in
    1) deploy ;;
    2) stop_app ;;
    3) restart_app ;;
    4) logs ;;
    5) remove_all ;;
    6) docker ps ;;
    7) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
done