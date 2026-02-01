#!/bin/bash

###############################################################################
# Quick Deploy to K8s (Updates existing deployments)
# Use after pushing images with build-multiarch.sh
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  ${1}${NC}"; }

NAMESPACE="petstore-demo"
REGISTRY="024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   Quick Deploy to Kubernetes                          ║"
echo "║   Updates backend and frontend deployments            ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

echo ""
log_info "Updating backend deployment..."
kubectl set image deployment/backend backend=$REGISTRY/backend:latest \
    -n $NAMESPACE --record
log_success "Backend image updated"

echo ""
log_info "Updating frontend deployment..."
kubectl set image deployment/frontend frontend=$REGISTRY/frontend:latest \
    -n $NAMESPACE --record
log_success "Frontend image updated"

echo ""
log_info "Waiting for backend rollout..."
kubectl rollout status deployment/backend -n $NAMESPACE --timeout=5m

echo ""
log_info "Waiting for frontend rollout..."
kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=5m

echo ""
log_success "Deployments updated successfully! ✨"

echo ""
log_info "Current status:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
log_info "View logs:"
echo "  Backend:  kubectl logs -n $NAMESPACE -l app=backend -f"
echo "  Frontend: kubectl logs -n $NAMESPACE -l app=frontend -f"
