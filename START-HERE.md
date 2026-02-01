# 🚀 Quick Start - Multi-Architecture Deployment

**Everything is ready to deploy!**

---

## ⚡ 30-Second Setup

### Step 1: Enable buildx (one-time)
```bash
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

### Step 2: Build & Push to ECR
```bash
./scripts/build-multiarch.sh
```

**What it does:**
- Logs into ECR
- Builds `linux/arm64` + `linux/amd64` images
- Pushes to ECR
- Verifies both architectures

### Step 3: Deploy to K8s
```bash
./scripts/deploy.sh
```

**What it does:**
- Updates backend deployment image
- Updates frontend deployment image
- Waits for rollout
- Shows pod status

---

## 📊 Result
```
✅ Pods running
✅ Multi-architecture images
✅ Works on ARM64 EKS
✅ Works on amd64 (your laptop)
```

---

## 🔍 Verify

### Check pods
```bash
kubectl get pods -n petstore-demo
```

### View logs
```bash
kubectl logs -n petstore-demo -l app=backend -f
```

### Test backend
```bash
kubectl port-forward -n petstore-demo svc/backend 8000:8000
# In another terminal: curl http://localhost:8000/
```

---

## 🚀 Alternative: Automatic (GitHub Actions)

Just push to main:
```bash
git add .
git commit -m "Deploy petstore"
git push origin main
```

GitHub Actions will automatically:
1. Build multi-arch images
2. Push to ECR
3. Deploy to EKS
4. Verify rollout

---

## 📝 Commands Reference

| Task | Command |
|------|---------|
| Build locally | `./scripts/build-multiarch.sh` |
| Deploy to K8s | `./scripts/deploy.sh` |
| Check status | `kubectl get pods -n petstore-demo -o wide` |
| View logs | `kubectl logs -n petstore-demo -l app=backend -f` |
| Validate config | `./scripts/validate.sh` |
| Local dev test | `./scripts/local-dev.sh start` |

---

## 🎯 Architecture

```
Your Laptop (amd64)          EKS Cluster (ARM64)
       ↓                              ↓
Build multi-arch image ──→  Docker Registry (ECR)
       ↓                              ↓
  amd64 version          arm64 version
   (your machine)         (EKS nodes)
```

Both versions are built automatically! 🎉

---

## ✅ Done!

Everything is configured for production-ready multi-architecture deployment.

**Next**: `./scripts/build-multiarch.sh` → `./scripts/deploy.sh` → Success! 🚀
