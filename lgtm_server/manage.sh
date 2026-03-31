#!/bin/bash

############################################################
#           🚀 LGTM STACK MANAGEMENT SCRIPT               #
#----------------------------------------------------------#
# 1) Setup Environment (Docker install, etc.)             #
# 2) Start Stack                                           #
# 3) Stop Stack                                            #
# 4) Restart Stack                                         #
# 5) Status                                               #
# 6) Recreate Stack                                       #
# 7) Ensure Running                                       #
# 8) Exit                                                 #
############################################################

COMPOSE_FILE="docker-compose.yml"

function setup_environment() {
    echo "🔧 Running setup..."

    sudo apt update -y

    if ! command -v docker &> /dev/null
    then
        echo "❌ Installing Docker..."
        sudo apt install -y docker.io
    else
        echo "✅ Docker already installed"
    fi

    if ! command -v docker-compose &> /dev/null
    then
        echo "❌ Installing Docker Compose..."
        sudo apt install -y docker-compose
    else
        echo "✅ Docker Compose already installed"
    fi

    sudo systemctl enable docker
    sudo systemctl start docker

    if ! groups $USER | grep -q docker
    then
        echo "➕ Adding user to docker group..."
        sudo usermod -aG docker $USER
        echo "⚠️ Logout & login required for docker permissions"
    else
        echo "✅ User already in docker group"
    fi

    echo "🎉 Setup completed"
}

function start_stack() {
    echo "▶ Starting LGTM stack..."
    docker-compose -f $COMPOSE_FILE up -d
}

function stop_stack() {
    echo "⛔ Stopping LGTM stack..."
    docker-compose -f $COMPOSE_FILE down
}

function restart_stack() {
    echo "🔄 Restarting LGTM stack..."
    docker-compose -f $COMPOSE_FILE down
    docker-compose -f $COMPOSE_FILE up -d
}

function status_stack() {
    echo "📊 Container Status:"
    docker ps -a
}

function recreate_stack() {
    echo "♻️ Recreating stack..."
    docker-compose -f $COMPOSE_FILE down -v
    docker-compose -f $COMPOSE_FILE up -d --build
}

function ensure_running() {
    echo "🔍 Ensuring all containers are running..."
    docker-compose -f $COMPOSE_FILE up -d
}

############################
# 🎯 MENU LOOP
############################

while true
do
    echo ""
    echo "======================================================"
    echo "🚀 LGTM STACK MENU"
    echo "======================================================"
    echo "1) Setup Environment (Docker, etc.)"
    echo "2) Start Stack"
    echo "3) Stop Stack"
    echo "4) Restart Stack"
    echo "5) Status"
    echo "6) Recreate Stack"
    echo "7) Ensure Running"
    echo "8) Exit"
    echo "======================================================"
    read -p "👉 Enter your choice [1-8]: " choice

    case $choice in
        1)
            setup_environment
            ;;
        2)
            start_stack
            ;;
        3)
            stop_stack
            ;;
        4)
            restart_stack
            ;;
        5)
            status_stack
            ;;
        6)
            recreate_stack
            ;;
        7)
            ensure_running
            ;;
        8)
            echo "👋 Exiting..."
            break
            ;;
        *)
            echo "❌ Invalid option. Please choose 1-8."
            ;;
    esac
done