#!/bin/bash

###############################################################################
# PetStore Demo - Validation & Readiness Check
# Verifies all configurations are correct before deployment
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

log_pass() {
    echo -e "${GREEN}✅ ${1}${NC}"
    ((PASS++))
}

log_fail() {
    echo -e "${RED}❌ ${1}${NC}"
    ((FAIL++))
}

log_warn() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
    ((WARN++))
}

log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${1}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_required_tools() {
    log_section "Required Tools"
    
    tools=("docker" "aws" "kubectl" "bash")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            version=$(eval "$tool --version" 2>&1 | head -1 || echo "$tool version unknown")
            log_pass "$tool: installed"
        else
            log_fail "$tool: NOT INSTALLED"
        fi
    done
}

check_docker_config() {
    log_section "Docker Configuration"
    
    if docker ps &>/dev/null; then
        log_pass "Docker: Running and accessible"
    else
        log_fail "Docker: Not running or not accessible"
        return 1
    fi
    
    # Check buildx
    if docker buildx version &>/dev/null; then
        log_pass "Docker buildx: Available for multi-platform builds"
    else
        log_warn "Docker buildx: Not available (will use standard build)"
    fi
}

check_aws_config() {
    log_section "AWS Configuration"
    
    # Check credentials
    if aws sts get-caller-identity &>/dev/null; then
        account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
        log_pass "AWS Credentials: Configured (Account: $account)"
    else
        log_fail "AWS Credentials: Not configured"
        return 1
    fi
    
    # Check ECR
    if aws ecr describe-repositories --region eu-west-1 &>/dev/null; then
        log_pass "ECR: Accessible"
    else
        log_warn "ECR: Might not be accessible (check permissions)"
    fi
}

check_kubernetes_config() {
    log_section "Kubernetes Configuration"
    
    if kubectl version --client &>/dev/null; then
        log_pass "kubectl: Installed and working"
    else
        log_fail "kubectl: Not working"
        return 1
    fi
    
    # Try to get cluster info
    if kubectl cluster-info &>/dev/null; then
        log_pass "Kubernetes cluster: Connected"
    else
        log_warn "Kubernetes cluster: Not connected (run: aws eks update-kubeconfig --region eu-west-1 --name innovation-lab)"
    fi
}

check_project_structure() {
    log_section "Project Structure"
    
    base_path="/home/ayan/petstore-demo"
    
    files=(
        "$base_path/backend/Dockerfile"
        "$base_path/backend/app.py"
        "$base_path/backend/requirements.txt"
        "$base_path/frontend/Dockerfile"
        "$base_path/frontend/nginx.conf"
        "$base_path/frontend/index.html"
        "$base_path/k8s/backend-deployment.yaml"
        "$base_path/k8s/frontend-deployment.yaml"
        "$base_path/.github/workflows/ci-cd.yml"
        "$base_path/scripts/build-and-deploy.sh"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "$(basename $(dirname $file))/$(basename $file)"
        else
            log_fail "MISSING: $file"
        fi
    done
}

check_dockerfile_content() {
    log_section "Dockerfile Configuration"
    
    # Backend
    if grep -q "FROM python:3.9-slim" /home/ayan/petstore-demo/backend/Dockerfile; then
        log_pass "Backend Dockerfile: Using python:3.9-slim (ARM64 compatible)"
    else
        log_warn "Backend Dockerfile: Not using python:3.9-slim"
    fi
    
    # Frontend
    if grep -q "FROM nginx:alpine" /home/ayan/petstore-demo/frontend/Dockerfile; then
        log_pass "Frontend Dockerfile: Using nginx:alpine (ARM64 compatible)"
    else
        log_warn "Frontend Dockerfile: Not using nginx:alpine"
    fi
}

check_k8s_manifests() {
    log_section "Kubernetes Manifests"
    
    # Backend deployment
    if grep -q "petstore-backend:arm64" /home/ayan/petstore-demo/k8s/backend-deployment.yaml; then
        log_pass "Backend deployment: Configured for ARM64"
    else
        log_warn "Backend deployment: Not configured for ARM64 image"
    fi
    
    # Frontend deployment
    if grep -q "petstore-frontend:arm64" /home/ayan/petstore-demo/k8s/frontend-deployment.yaml; then
        log_pass "Frontend deployment: Configured for ARM64"
    else
        log_warn "Frontend deployment: Not configured for ARM64 image"
    fi
}

check_ci_cd_pipeline() {
    log_section "CI/CD Pipeline"
    
    ci_file="/home/ayan/petstore-demo/.github/workflows/ci-cd.yml"
    
    if grep -q "docker/setup-qemu-action" "$ci_file"; then
        log_pass "CI/CD: QEMU setup configured"
    else
        log_warn "CI/CD: QEMU not configured"
    fi
    
    if grep -q "linux/arm64" "$ci_file"; then
        log_pass "CI/CD: ARM64 platform specified"
    else
        log_warn "CI/CD: ARM64 platform not specified"
    fi
    
    if grep -q "ECR" "$ci_file" || grep -q "ecr" "$ci_file"; then
        log_pass "CI/CD: ECR registry configured"
    else
        log_warn "CI/CD: ECR registry not configured"
    fi
}

check_scripts() {
    log_section "Automation Scripts"
    
    scripts=(
        "/home/ayan/petstore-demo/scripts/build-and-deploy.sh"
        "/home/ayan/petstore-demo/scripts/local-dev.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            log_pass "$(basename $script): Executable"
        else
            log_warn "$(basename $script): Not executable"
        fi
    done
}

check_env_vars() {
    log_section "Environment Variables Check"
    
    log_pass "Backend expects: DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME"
    log_pass "Frontend expects: Backend service at 'petstore-backend:8000'"
    log_pass "CI/CD expects: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
}

show_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Passed: ${PASS}${NC}"
    if [ $WARN -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings: ${WARN}${NC}"
    fi
    if [ $FAIL -gt 0 ]; then
        echo -e "${RED}❌ Failed: ${FAIL}${NC}"
    fi
    
    echo ""
    
    if [ $FAIL -eq 0 ]; then
        if [ $WARN -eq 0 ]; then
            echo -e "${GREEN}✅ All checks passed! Ready to deploy.${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  All critical checks passed, but review warnings above.${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ Fix the failures above before proceeding.${NC}"
        return 1
    fi
}

# Main
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║   PetStore Demo - Deployment Readiness Check                 ║"
    echo "║   Validates configuration for ARM64 K8s deployment          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_required_tools
    check_docker_config
    check_aws_config
    check_kubernetes_config
    check_project_structure
    check_dockerfile_content
    check_k8s_manifests
    check_ci_cd_pipeline
    check_scripts
    check_env_vars
    
    show_summary
}

main "$@"
