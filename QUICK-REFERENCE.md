# Quick Reference - PetStore ARM64 Deployment

## 🚀 Quick Start Commands

### Local Testing
```bash
# Build images
./scripts/build-and-deploy.sh --build-only

# Push to ECR
./scripts/build-and-deploy.sh --push-only

# Deploy to K8s
./scripts/build-and-deploy.sh --deploy-only

# Verify
./scripts/build-and-deploy.sh --verify-only
```

### View Status
```bash
# Deployments
kubectl get deployments -n petstore-demo

# Pods
kubectl get pods -n petstore-demo -o wide

# Services
kubectl get svc -n petstore-demo

# Logs
kubectl logs -n petstore-demo -l app=petstore-backend
kubectl logs -n petstore-demo -l app=petstore-frontend
```

### Debug
```bash
# Port forward backend
kubectl port-forward -n petstore-demo svc/petstore-backend 8000:8000

# Port forward frontend
kubectl port-forward -n petstore-demo svc/petstore-frontend 8080:80

# Describe pod
kubectl describe pod -n petstore-demo <pod-name>

# Check recent events
kubectl get events -n petstore-demo --sort-by='.lastTimestamp'
```

### Restart
```bash
kubectl rollout restart deployment/petstore-backend -n petstore-demo
kubectl rollout restart deployment/petstore-frontend -n petstore-demo
```

### Delete
```bash
kubectl delete deployment -n petstore-demo petstore-backend
kubectl delete deployment -n petstore-demo petstore-frontend
kubectl delete service -n petstore-demo petstore-backend
kubectl delete service -n petstore-demo petstore-frontend
```

## 📋 Checklist - Pre-Demo

- [ ] AWS credentials configured (`aws configure`)
- [ ] kubectl installed and accessible
- [ ] EKS cluster running (`innovation-lab`)
- [ ] ECR registry ready
- [ ] Docker installed with buildx support
- [ ] `scripts/build-and-deploy.sh` is executable
- [ ] GitHub secrets configured (for CI/CD):
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

## 🔄 CI/CD Pipeline

Automatic on push to `main`:
1. ✅ Checkout code
2. ✅ Setup QEMU (multi-platform)
3. ✅ Login to ECR
4. ✅ Build backend (ARM64)
5. ✅ Push backend
6. ✅ Build frontend (ARM64)
7. ✅ Push frontend
8. ✅ Deploy to EKS
9. ✅ Wait for rollout
10. ✅ Verify deployment

**Trigger:** Push to `main` branch
**Duration:** ~10-15 minutes
**Output:** Check GitHub Actions workflow tab

## 📊 Resource Usage

**Backend Pod:**
- Requests: 250m CPU, 256Mi RAM
- Limits: 500m CPU, 512Mi RAM

**Frontend Pod (×2):**
- Requests: 100m CPU, 128Mi RAM
- Limits: 200m CPU, 256Mi RAM

**Total Cluster Requirements:**
- Min: 450m CPU, 512Mi RAM
- Max: 900m CPU, 1Gi RAM

## 🐛 Common Issues

**Pods stuck in Pending:**
```bash
kubectl describe pod <name> -n petstore-demo
# Check node availability, resources, or image pull errors
```

**Image pull errors:**
```bash
# Verify ECR login
aws ecr get-login-password --region eu-west-1 | docker login ...

# Check image exists
aws ecr describe-images --repository-name petstore-backend --region eu-west-1
```

**Backend not responding:**
```bash
kubectl logs -n petstore-demo -l app=petstore-backend
# Check for Python errors or missing dependencies
```

**Frontend showing errors:**
```bash
kubectl logs -n petstore-demo -l app=petstore-frontend
# Check nginx configuration and backend connectivity
```

## 🔗 Service Discovery

**Within cluster:**
- Backend: `http://petstore-backend:8000/`
- Frontend: `http://petstore-frontend/`

**From outside cluster:**
- Use port-forward or ingress
- Ingress rule: `petstore.example.com`

## 📈 Metrics & Monitoring

**Prometheus endpoints:**
- Backend: `:8000/metrics` (configure in app)
- Frontend: `:80/metrics` (configure in nginx)

**Health endpoints:**
- Backend: `http://localhost:8000/`
- Frontend: `http://localhost/health`

## 🔐 Security Tips

✅ Use AWS Secrets Manager for DB credentials
✅ Enable Pod Security Policies
✅ Implement Network Policies
✅ Use private ECR repositories
✅ Enable audit logging on EKS
✅ Regularly update base images

## 📞 Support

For issues:
1. Check logs: `kubectl logs -n petstore-demo ...`
2. Check events: `kubectl get events -n petstore-demo`
3. Describe resources: `kubectl describe pod/svc -n petstore-demo`
4. Review GitHub Actions for CI/CD failures
