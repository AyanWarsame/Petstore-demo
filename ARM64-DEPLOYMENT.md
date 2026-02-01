# PetStore Demo - ARM64 Configuration Guide

## Overview
This project is configured for ARM64 (Apple Silicon, AWS Graviton2, etc.) Kubernetes deployments with optimized Docker images and robust deployment pipelines.

## Architecture

```
Frontend (Nginx)
    ↓
API Gateway (Nginx Proxy)
    ↓
Backend (Flask + Gunicorn)
    ↓
Database (MySQL/SQLite)
```

## Key Features

✅ **ARM64 Compatible**
- Python 3.9-slim base (ARM64 optimized)
- nginx:alpine (ARM64 optimized)
- Multi-platform Docker builds

✅ **Production Ready**
- Gunicorn with optimized worker count
- Health checks and readiness probes
- Resource limits and requests
- Security contexts
- Rolling updates strategy

✅ **Kubernetes Native**
- Service discovery
- ConfigMaps and Secrets
- Pod anti-affinity
- Ingress support
- Rolling deployments

✅ **CI/CD Automated**
- GitHub Actions workflow
- Automatic ARM64 builds
- ECR image registry
- EKS deployment automation

## File Structure

```
.
├── backend/
│   ├── Dockerfile          # ARM64-optimized Python image
│   ├── app.py             # Flask application
│   ├── requirements.txt    # Python dependencies
│   └── uploads/           # User-uploaded files
├── frontend/
│   ├── Dockerfile         # ARM64-optimized nginx image
│   ├── nginx.conf         # Nginx configuration
│   ├── index.html         # SPA entry point
│   ├── style.css          # Styling
│   ├── script.js          # JavaScript
│   └── assets/            # Static assets
├── k8s/
│   ├── namespace.yaml     # Kubernetes namespace
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-configmap.yaml
│   └── ingress.yaml
├── scripts/
│   └── build-and-deploy.sh # Deployment automation script
└── .github/workflows/
    └── ci-cd.yml          # GitHub Actions workflow
```

## Prerequisites

### Local Development
- Docker with buildx support (for ARM64 builds)
- kubectl
- AWS CLI v2
- bash

### AWS
- EKS cluster (innovation-lab)
- ECR registry
- IAM credentials

## Quick Start

### 1. Local Build & Push

```bash
# Make script executable
chmod +x scripts/build-and-deploy.sh

# Full pipeline (build → push → deploy)
./scripts/build-and-deploy.sh

# Or individual stages
./scripts/build-and-deploy.sh --build-only
./scripts/build-and-deploy.sh --push-only
./scripts/build-and-deploy.sh --deploy-only
```

### 2. Using GitHub Actions

Simply push to the `main` branch:
```bash
git add .
git commit -m "Update petstore deployment"
git push origin main
```

The workflow will automatically:
1. Build ARM64 images
2. Push to ECR
3. Deploy to EKS
4. Verify rollout

### 3. Manual kubectl Deployment

```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name innovation-lab

# Create namespace
kubectl create namespace petstore-demo

# Deploy backend
kubectl apply -n petstore-demo -f k8s/backend-deployment.yaml

# Deploy frontend
kubectl apply -n petstore-demo -f k8s/frontend-deployment.yaml

# Deploy ingress
kubectl apply -n petstore-demo -f k8s/ingress.yaml

# Watch rollout
kubectl rollout status deployment/petstore-backend -n petstore-demo -w
kubectl rollout status deployment/petstore-frontend -n petstore-demo -w
```

## Configuration

### Environment Variables

**Backend** (app.py):
```
DB_USER=Petstore
DB_PASSWORD=(from secret)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=petstore_db
FLASK_ENV=production
PYTHONUNBUFFERED=1
```

**Frontend** (nginx.conf):
- API proxy URL: `http://petstore-backend:8000/`
- Health endpoint: `/health`

### Kubernetes Resources

**Backend Deployment:**
- Replicas: 1
- CPU: 250m (request) → 500m (limit)
- Memory: 256Mi (request) → 512Mi (limit)
- Image: `024848484634.dkr.ecr.eu-west-1.amazonaws.com/petstore-backend:arm64`

**Frontend Deployment:**
- Replicas: 2
- CPU: 100m (request) → 200m (limit)
- Memory: 128Mi (request) → 256Mi (limit)
- Image: `024848484634.dkr.ecr.eu-west-1.amazonaws.com/petstore-frontend:arm64`

### Nginx Configuration

Key features:
- Gzip compression enabled
- Security headers configured
- API proxy to backend service
- SPA fallback to index.html
- Static asset caching (30 days)
- Health check endpoint at `/health`

## Troubleshooting

### Check pod status
```bash
kubectl get pods -n petstore-demo -o wide
kubectl describe pod <pod-name> -n petstore-demo
```

### View logs
```bash
# Backend
kubectl logs -n petstore-demo -l app=petstore-backend -f

# Frontend
kubectl logs -n petstore-demo -l app=petstore-frontend -f
```

### Check services
```bash
kubectl get svc -n petstore-demo
kubectl get endpoints -n petstore-demo
```

### Port forward for testing
```bash
# Backend
kubectl port-forward -n petstore-demo svc/petstore-backend 8000:8000

# Frontend
kubectl port-forward -n petstore-demo svc/petstore-frontend 8080:80

# In another terminal
curl http://localhost:8000/
curl http://localhost:8080/
```

### Restart deployment
```bash
kubectl rollout restart deployment/petstore-backend -n petstore-demo
kubectl rollout restart deployment/petstore-frontend -n petstore-demo
```

### View recent events
```bash
kubectl get events -n petstore-demo --sort-by='.lastTimestamp'
```

## Image Building Details

### Backend Image (ARM64)

Base: `python:3.9-slim` (arm64 compatible)

Dependencies:
- gcc (for native extensions)
- libc-dev, libffi-dev, libssl-dev (for compilation)
- Flask, SQLAlchemy, pymysql (runtime)
- gunicorn 21.2.0 (production server)

Build command:
```bash
docker buildx build --platform linux/arm64 -t petstore-backend:arm64 ./backend
```

### Frontend Image (ARM64)

Base: `nginx:alpine` (arm64 compatible)

Features:
- Gzip compression
- Security headers
- API proxy
- Health checks
- Non-root user (nginx)

Build command:
```bash
docker buildx build --platform linux/arm64 -t petstore-frontend:arm64 ./frontend
```

## Security Considerations

✅ **Implemented:**
- Non-root containers (frontend)
- Read-only root filesystem (frontend)
- Security contexts
- Resource limits
- Network policies (ingress)
- HTTPS ready (ingress annotations)

⚠️ **Recommendations:**
- Use Secrets for sensitive data (database passwords)
- Enable Pod Security Policies
- Use Network Policies
- Implement RBAC
- Enable audit logging
- Use private ECR repositories
- Regularly update base images

## Performance Tuning

### Backend (Gunicorn)
- Workers: 2 (ARM64 optimized)
- Worker class: sync (default)
- Timeout: 60s
- Buffer: 4KB

For more workers, adjust in `k8s/backend-deployment.yaml`:
```yaml
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "app:app"]
```

### Frontend (Nginx)
- Gzip enabled for text-based content
- Buffer size: 4KB per buffer
- Caching headers set
- Connection pooling enabled

## Monitoring & Logging

Currently configured:
- Kubernetes resource metrics
- Container logs (stdout/stderr)
- Prometheus annotations (for Prometheus scraping)
- Liveness and readiness probes

Recommended additions:
- Prometheus + Grafana for metrics
- ELK stack for centralized logging
- AWS CloudWatch for monitoring

## Related Documentation

- [Kubernetes Deployment Docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
