#!/bin/bash
set -e

DOCKER_USERNAME="sakit333"
IMAGE_NAME="coorgcult-api"
TAG="latest"
FULL_IMAGE="$DOCKER_USERNAME/$IMAGE_NAME:$TAG"

echo "========================================================"
echo "🐳 Docker Build & Push Script for CoorgCult            "
echo "========================================================"

echo "➡️ Checking Docker Login..."
if ! docker info | grep -q 'Username'; then
    echo "⚠️  You are not logged into Docker Hub. Please authenticate:"
    docker login
fi

echo "➡️ Building Docker image: $FULL_IMAGE..."
# Using buildx with platform flag to ensure compatibility with standard EC2 (x86_64) servers
# even if you build this locally on an M-series Mac!
docker build --platform linux/amd64 -t $FULL_IMAGE .

echo "➡️ Pushing image to Docker Hub..."
docker push $FULL_IMAGE

echo "========================================================"
echo "✅ Pipeline complete!"
echo "Image $FULL_IMAGE is ready for Kubeadm deployment."
echo "========================================================"
