#!/bin/bash

###############################################################################
# Multi-Architecture Docker Build & Push to ECR
# Builds arm64 + amd64 images and pushes to ECR
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_error() { echo -e "${RED}❌ ${1}${NC}"; }

# Configuration
REGISTRY="024848484634.dkr.ecr.eu-west-1.amazonaws.com"
REGISTRY_PATH="ayan-warsame"
AWS_REGION="eu-west-1"

log_info "Multi-Architecture Docker Build & Push"
echo ""

# Check if buildx exists
if ! docker buildx ls &>/dev/null; then
    log_info "Creating buildx builder..."
    docker buildx create --name multiarch --use
    docker buildx inspect --bootstrap
fi

# Login to ECR
log_info "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $REGISTRY
log_success "ECR login successful"

echo ""

# Build backend
log_info "Building backend (linux/arm64,linux/amd64)..."
docker buildx build \
    --platform linux/arm64,linux/amd64 \
    -t $REGISTRY/$REGISTRY_PATH/backend:latest \
    --push \
    ./backend
log_success "Backend built and pushed"

echo ""

# Build frontend
log_info "Building frontend (linux/arm64,linux/amd64)..."
docker buildx build \
    --platform linux/arm64,linux/amd64 \
    -t $REGISTRY/$REGISTRY_PATH/frontend:latest \
    --push \
    ./frontend
log_success "Frontend built and pushed"

echo ""

# Verify architectures
log_info "Verifying image architectures..."
echo ""

log_info "Backend image manifest:"
docker manifest inspect $REGISTRY/$REGISTRY_PATH/backend:latest | grep -A 2 "architecture" || echo "Checking..."

echo ""

log_info "Frontend image manifest:"
docker manifest inspect $REGISTRY/$REGISTRY_PATH/frontend:latest | grep -A 2 "architecture" || echo "Checking..."

echo ""
log_success "Build and push complete! ✨"
echo ""
echo "🚀 Images ready for deployment:"
echo "  Backend:  $REGISTRY/$REGISTRY_PATH/backend:latest"
echo "  Frontend: $REGISTRY/$REGISTRY_PATH/frontend:latest"
echo ""
echo "📝 Next: kubectl rollout restart deployment/backend -n petstore-demo"
echo "         kubectl rollout restart deployment/frontend -n petstore-demo"
