#!/bin/bash

###############################################################################
# PetStore Demo - Local Development Script
# For quick local testing with Docker Compose
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
log_error() { echo -e "${RED}❌ ${1}${NC}"; }

# Check if Docker is running
check_docker() {
    log_info "Checking Docker..."
    if ! docker ps &>/dev/null; then
        log_error "Docker is not running or not accessible"
        return 1
    fi
    log_success "Docker is running"
}

# Build local images
build_local() {
    log_info "Building Docker images locally..."
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    log_info "Building backend..."
    docker build -t petstore-backend:local ./backend
    log_success "Backend built"
    
    log_info "Building frontend..."
    docker build -t petstore-frontend:local ./frontend
    log_success "Frontend built"
}

# Start services
start_services() {
    log_info "Starting services with Docker Compose..."
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    docker-compose -f docker-compose.prod.yml up -d
    
    log_success "Services started in background"
    
    log_info "Waiting for services to be ready..."
    sleep 5
    
    # Wait for backend
    for i in {1..30}; do
        if curl -s http://localhost:8000/ &>/dev/null; then
            log_success "Backend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            log_warning "Backend took too long to start"
        fi
        echo -n "."
        sleep 1
    done
    
    # Wait for frontend
    for i in {1..30}; do
        if curl -s http://localhost/ &>/dev/null; then
            log_success "Frontend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            log_warning "Frontend took too long to start"
        fi
        echo -n "."
        sleep 1
    done
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    docker-compose -f docker-compose.prod.yml down
    
    log_success "Services stopped"
}

# Show status
show_status() {
    log_info "Service Status:"
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    docker-compose -f docker-compose.prod.yml ps
    
    echo ""
    log_info "Service URLs:"
    echo -e "  Frontend: ${BLUE}http://localhost${NC}"
    echo -e "  Backend:  ${BLUE}http://localhost:8000${NC}"
    echo -e "  MySQL:    ${BLUE}localhost:3306${NC}"
}

# View logs
show_logs() {
    log_info "Showing logs for: $1"
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    docker-compose -f docker-compose.prod.yml logs -f "$1"
}

# Test endpoints
test_endpoints() {
    log_info "Testing endpoints..."
    
    echo ""
    log_info "Backend health check:"
    if curl -s http://localhost:8000/ | head -c 100; then
        echo ""
        log_success "Backend responding"
    else
        log_error "Backend not responding"
    fi
    
    echo ""
    log_info "Frontend health check:"
    if curl -s http://localhost/ | head -c 100; then
        echo ""
        log_success "Frontend responding"
    else
        log_error "Frontend not responding"
    fi
    
    echo ""
    log_info "API test:"
    if curl -s http://localhost:8000/pets -H "Content-Type: application/json" | head -c 100; then
        echo ""
        log_success "API working"
    else
        log_warning "API not responding or no data"
    fi
}

# Clean up volumes
cleanup() {
    log_warning "Cleaning up all services and volumes..."
    
    cd "$(dirname "${BASH_SOURCE[0]}")"
    docker-compose -f docker-compose.prod.yml down -v
    
    log_success "Cleanup complete"
}

# Main
main() {
    case "${1:-help}" in
        build)
            check_docker
            build_local
            ;;
        start)
            check_docker
            build_local
            start_services
            show_status
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            sleep 2
            start_services
            show_status
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-backend}"
            ;;
        test)
            test_endpoints
            ;;
        clean)
            cleanup
            ;;
        shell-backend)
            cd "$(dirname "${BASH_SOURCE[0]}")"
            docker-compose -f docker-compose.prod.yml exec backend bash
            ;;
        shell-frontend)
            cd "$(dirname "${BASH_SOURCE[0]}")"
            docker-compose -f docker-compose.prod.yml exec frontend sh
            ;;
        shell-mysql)
            cd "$(dirname "${BASH_SOURCE[0]}")"
            docker-compose -f docker-compose.prod.yml exec mysql mysql -uroot -proot123
            ;;
        help|*)
            echo "PetStore Demo - Local Development Commands"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  build              Build Docker images"
            echo "  start              Build and start all services"
            echo "  stop               Stop all services"
            echo "  restart            Restart all services"
            echo "  status             Show service status"
            echo "  logs [service]     View logs (default: backend)"
            echo "  test               Test API endpoints"
            echo "  clean              Remove all services and volumes"
            echo "  shell-backend      Open bash shell in backend container"
            echo "  shell-frontend     Open sh shell in frontend container"
            echo "  shell-mysql        Open mysql shell in database"
            echo ""
            echo "Examples:"
            echo "  $0 start           # Start everything"
            echo "  $0 logs frontend   # Watch frontend logs"
            echo "  $0 test            # Test endpoints"
            echo ""
            ;;
    esac
}

main "$@"
