#!/bin/bash

###############################################################################
# PetStore Demo - ARM64 Build and Deploy Script
# This script builds ARM64-compatible Docker images and deploys to EKS
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="024848484634.dkr.ecr.eu-west-1.amazonaws.com"
AWS_REGION="eu-west-1"
EKS_CLUSTER="innovation-lab"
K8S_NAMESPACE="petstore-demo"
BUILD_PLATFORM="linux/arm64"

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then missing_tools+=("docker"); fi
    if ! command -v aws &> /dev/null; then missing_tools+=("aws"); fi
    if ! command -v kubectl &> /dev/null; then missing_tools+=("kubectl"); fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

# Build Docker images
build_images() {
    log_info "Building Docker images for ARM64..."
    
    cd "$PROJECT_ROOT"
    
    # Build backend
    log_info "Building backend image..."
    BACKEND_TAG="$REGISTRY/petstore-backend:arm64"
    
    if docker buildx build \
        --platform "$BUILD_PLATFORM" \
        -t "$BACKEND_TAG" \
        -f ./backend/Dockerfile \
        --load \
        ./backend 2>/dev/null; then
        log_success "Backend image built: $BACKEND_TAG"
    else
        log_warning "Using docker build (buildx not available)..."
        docker build \
            -t "$BACKEND_TAG" \
            -f ./backend/Dockerfile \
            ./backend
        log_success "Backend image built: $BACKEND_TAG"
    fi
    
    # Build frontend
    log_info "Building frontend image..."
    FRONTEND_TAG="$REGISTRY/petstore-frontend:arm64"
    
    if docker buildx build \
        --platform "$BUILD_PLATFORM" \
        -t "$FRONTEND_TAG" \
        -f ./frontend/Dockerfile \
        --load \
        ./frontend 2>/dev/null; then
        log_success "Frontend image built: $FRONTEND_TAG"
    else
        log_warning "Using docker build (buildx not available)..."
        docker build \
            -t "$FRONTEND_TAG" \
            -f ./frontend/Dockerfile \
            ./frontend
        log_success "Frontend image built: $FRONTEND_TAG"
    fi
}

# Push images to ECR
push_images() {
    log_info "Pushing images to ECR..."
    
    # Login to ECR
    log_info "Logging in to Amazon ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "$REGISTRY" || {
        log_error "Failed to login to ECR"
        return 1
    }
    
    # Push backend
    BACKEND_TAG="$REGISTRY/petstore-backend:arm64"
    log_info "Pushing backend image..."
    docker push "$BACKEND_TAG"
    log_success "Backend image pushed"
    
    # Push frontend
    FRONTEND_TAG="$REGISTRY/petstore-frontend:arm64"
    log_info "Pushing frontend image..."
    docker push "$FRONTEND_TAG"
    log_success "Frontend image pushed"
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl for EKS..."
    
    aws eks update-kubeconfig \
        --region "$AWS_REGION" \
        --name "$EKS_CLUSTER" || {
        log_error "Failed to configure kubectl"
        return 1
    }
    
    log_success "kubectl configured"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $K8S_NAMESPACE..."
    
    if kubectl get namespace "$K8S_NAMESPACE" &>/dev/null; then
        log_warning "Namespace already exists"
    else
        kubectl create namespace "$K8S_NAMESPACE"
        log_success "Namespace created"
    fi
}

# Deploy to Kubernetes
deploy_to_k8s() {
    log_info "Deploying to Kubernetes..."
    
    cd "$PROJECT_ROOT"
    
    # Apply backend deployment
    log_info "Deploying backend..."
    kubectl apply -n "$K8S_NAMESPACE" -f k8s/backend-deployment.yaml
    
    # Apply frontend deployment
    log_info "Deploying frontend..."
    kubectl apply -n "$K8S_NAMESPACE" -f k8s/frontend-deployment.yaml
    
    # Apply configmap and ingress
    log_info "Applying additional resources..."
    kubectl apply -n "$K8S_NAMESPACE" -f k8s/frontend-configmap.yaml 2>/dev/null || true
    kubectl apply -n "$K8S_NAMESPACE" -f k8s/ingress.yaml 2>/dev/null || true
    
    log_success "Kubernetes deployment complete"
}

# Wait for rollout
wait_for_rollout() {
    log_info "Waiting for deployments to be ready..."
    
    # Wait for backend
    log_info "Waiting for backend deployment..."
    if kubectl rollout status deployment/petstore-backend \
        -n "$K8S_NAMESPACE" \
        --timeout=5m; then
        log_success "Backend deployment ready"
    else
        log_warning "Backend deployment timeout"
    fi
    
    # Wait for frontend
    log_info "Waiting for frontend deployment..."
    if kubectl rollout status deployment/petstore-frontend \
        -n "$K8S_NAMESPACE" \
        --timeout=5m; then
        log_success "Frontend deployment ready"
    else
        log_warning "Frontend deployment timeout"
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    echo ""
    log_info "Deployments:"
    kubectl get deployments -n "$K8S_NAMESPACE"
    
    echo ""
    log_info "Pods:"
    kubectl get pods -n "$K8S_NAMESPACE" -o wide
    
    echo ""
    log_info "Services:"
    kubectl get services -n "$K8S_NAMESPACE"
    
    echo ""
    log_info "Recent pod logs (backend):"
    kubectl logs -n "$K8S_NAMESPACE" \
        -l app=petstore-backend \
        --tail=20 2>/dev/null || log_warning "No backend logs yet"
    
    echo ""
    log_info "Recent pod logs (frontend):"
    kubectl logs -n "$K8S_NAMESPACE" \
        -l app=petstore-frontend \
        --tail=20 2>/dev/null || log_warning "No frontend logs yet"
}

# Main function
main() {
    log_info "Starting PetStore Demo deployment (ARM64)..."
    
    # Parse arguments
    BUILD_ONLY=false
    PUSH_ONLY=false
    DEPLOY_ONLY=false
    VERIFY_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --push-only)
                PUSH_ONLY=true
                shift
                ;;
            --deploy-only)
                DEPLOY_ONLY=true
                shift
                ;;
            --verify-only)
                VERIFY_ONLY=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute stages
    if [ "$VERIFY_ONLY" = true ]; then
        configure_kubectl
        verify_deployment
    elif [ "$BUILD_ONLY" = true ]; then
        check_prerequisites
        build_images
    elif [ "$PUSH_ONLY" = true ]; then
        check_prerequisites
        push_images
    elif [ "$DEPLOY_ONLY" = true ]; then
        configure_kubectl
        create_namespace
        deploy_to_k8s
        wait_for_rollout
        verify_deployment
    else
        # Full pipeline
        check_prerequisites
        build_images
        push_images
        configure_kubectl
        create_namespace
        deploy_to_k8s
        wait_for_rollout
        verify_deployment
    fi
    
    log_success "Deployment complete! 🎉"
}

# Run main function
main "$@"
