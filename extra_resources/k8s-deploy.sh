#!/bin/bash
set -e

echo "🚀 Deploying CoorgCult directly to Kubernetes (Production)"
echo "Checking cluster connection..."
kubectl cluster-info > /dev/null

echo "➡️ 1. Provisioning Stateful Resources (Postgres DB & Redis Cache)..."
kubectl apply -f k8s/coorgcult-db.yaml

echo "Waiting for PostgreSQL/Redis pods to initialize..."
sleep 5

echo "➡️ 2. Establishing Configuration & Secrets..."
kubectl apply -f k8s/coorgcult-api.yaml

echo "========================================================="
echo "✅ All manifests successfully applied to cluster!"
echo ""
echo "Monitor Deployment status with:"
echo "  kubectl get pods -w"
echo ""
echo "Access the app exactly at: http://<NODE-IP>:30080"
echo "========================================================="
