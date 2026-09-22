#!/bin/bash
set -e

# Configuration
AWS_REGION="ap-south-1"

# Automatically fetch Account ID, or you can hardcode it here
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

BACKEND_IMAGE="${ECR_URL}/python-backend:latest"
FRONTEND_IMAGE="${ECR_URL}/python-frontend:latest"

echo "=========================================="
echo "1. Logging into AWS ECR ($AWS_REGION)..."
echo "=========================================="
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

echo "=========================================="
echo "2. Pulling Docker Images from ECR..."
echo "=========================================="
docker pull $BACKEND_IMAGE
docker pull $FRONTEND_IMAGE

echo "=========================================="
echo "3. Cleaning up old containers (if any)..."
echo "=========================================="
docker rm -f inventory_frontend inventory_backend inventory_db 2>/dev/null || true
docker network rm inventory_network 2>/dev/null || true

echo "=========================================="
echo "4. Setting up Docker Network..."
echo "=========================================="
docker network create inventory_network

echo "=========================================="
echo "5. Starting Database (PostgreSQL)..."
echo "=========================================="
docker run -d \
  --name inventory_db \
  --network inventory_network \
  --restart unless-stopped \
  -e POSTGRES_DB=inventory_db \
  -e POSTGRES_USER=inventory_user \
  -e POSTGRES_PASSWORD=inventory_pass \
  postgres:16-alpine

# Give the database a few seconds to initialize
echo "Waiting for database to initialize..."
sleep 10

echo "=========================================="
echo "6. Starting Backend (Python API)..."
echo "=========================================="
docker run -d \
  --name inventory_backend \
  --network inventory_network \
  --restart unless-stopped \
  -e DATABASE_URL="postgresql://inventory_user:inventory_pass@inventory_db:5432/inventory_db" \
  -e SECRET_KEY="super-secret-production-key" \
  -e FLASK_DEBUG="false" \
  $BACKEND_IMAGE

echo "=========================================="
echo "7. Starting Frontend (Nginx)..."
echo "=========================================="
docker run -d \
  --name inventory_frontend \
  --network inventory_network \
  --restart unless-stopped \
  -p 8080:80 \
  $FRONTEND_IMAGE

echo "=========================================="
echo "✅ Deployment Complete!"
echo "🚀 Access your app at: http://localhost:8080"
echo "=========================================="
