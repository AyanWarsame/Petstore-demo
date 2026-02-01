# 🚀 Multi-Architecture Deployment Workflow

**Problem Solved**: Building multi-architecture images (arm64 + amd64) for ECR deployment to ARM64 EKS cluster

---

## 🎯 The Challenge

Your setup:
- **Local machine**: amd64 (x86_64) 
- **EKS cluster**: ARM64 (Graviton2 nodes)
- **Issue**: Building amd64-only images → `CrashLoopBackOff` on ARM64 nodes

**Solution**: Build multi-architecture images that work on BOTH platforms

---

## ✅ What's Been Updated

### 1. CI/CD Pipeline (``.github/workflows/ci-cd.yml``)
- ✅ Removed Docker Hub references
- ✅ Using ECR (`024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame`)
- ✅ Multi-platform builds: `linux/arm64,linux/amd64`
- ✅ Using `docker/setup-buildx-action` for buildx
- ✅ Automatic verification of image architectures

### 2. Kubernetes Manifests
- ✅ Backend deployment uses: `024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/backend:latest`
- ✅ Frontend deployment uses: `024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/frontend:latest`
- ✅ `imagePullPolicy: IfNotPresent` for reliability

### 3. New Build Scripts
- ✅ `scripts/build-multiarch.sh` - Local multi-arch build & push
- ✅ `scripts/deploy.sh` - Quick K8s deployment

---

## 🛠️ How to Use

### Option 1: Automatic (Recommended for Production)

Simply push to `main`:
```bash
git add .
git commit -m "Update deployment"
git push origin main
```

**GitHub Actions will:**
1. Build `linux/arm64` + `linux/amd64` images
2. Push to ECR
3. Deploy to EKS
4. Verify rollout

---

### Option 2: Manual Multi-Arch Build (For Testing)

#### Step 1: Enable Docker buildx (one-time setup)
```bash
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

#### Step 2: Build and push (multi-arch)
```bash
# Automatic (handles login + build + push)
./scripts/build-multiarch.sh

# Or manual
docker buildx build \
  --platform linux/arm64,linux/amd64 \
  -t 024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/backend:latest \
  --push ./backend
```

#### Step 3: Deploy to K8s
```bash
# Automatic
./scripts/deploy.sh

# Or manual
kubectl rollout restart deployment/backend -n petstore-demo
kubectl rollout restart deployment/frontend -n petstore-demo
```

---

## 🔍 Verify Image Architecture

After building, check that both architectures are present:

```bash
# Inspect manifest
docker manifest inspect 024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/backend:latest
```

**Expected output:**
```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
  "manifests": [
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 7023,
      "digest": "sha256:...",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 7654,
      "digest": "sha256:...",
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    }
  ]
}
```

✅ If you see **BOTH `amd64` and `arm64`** → Success!

---

## 📝 Key Configuration Changes

### ECR Path Structure
```
024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/backend:latest
                                               ^^^^^^^^^^^
                                               Your registry namespace
```

### CI/CD Environment Variables
```yaml
REGISTRY: 024848484634.dkr.ecr.eu-west-1.amazonaws.com
REGISTRY_PATH: ayan-warsame
AWS_REGION: eu-west-1
```

### Docker Build Command
```bash
docker buildx build \
  --platform linux/arm64,linux/amd64    # ← Multi-arch
  -t [ECR_PATH]/backend:latest           # ← ECR image path
  --push                                 # ← Push during build
  ./backend
```

**Note**: `--push` is mandatory for multi-arch builds (can't use `--load`)

---

## 🔄 Deployment Flow

```
Code Push (main branch)
    ↓
GitHub Actions Workflow
    ├─ Checkout code
    ├─ Setup QEMU (multi-platform support)
    ├─ Setup buildx
    ├─ Login to ECR
    ├─ Build backend (arm64 + amd64) → Push to ECR
    ├─ Build frontend (arm64 + amd64) → Push to ECR
    ├─ Update K8s deployment images
    ├─ Wait for rollout
    └─ Verify pods running
```

---

## ✅ Expected Results

### Pod Status
```bash
$ kubectl get pods -n petstore-demo
NAME                       READY   STATUS    RESTARTS   AGE
backend-5d4d8f7d4c-abc12   1/1     Running   0          2m
frontend-7c9f6b2a1d-xyz98  1/1     Running   0          2m
frontend-7c9f6b2a1d-abc12  1/1     Running   0          2m
```

### View Logs
```bash
kubectl logs -n petstore-demo -l app=backend -f
kubectl logs -n petstore-demo -l app=frontend -f
```

### Test Connectivity
```bash
# Port forward
kubectl port-forward -n petstore-demo svc/backend 8000:8000

# In another terminal
curl http://localhost:8000/
```

---

## 🚨 Troubleshooting

### Issue: `CrashLoopBackOff`

**Check image architecture:**
```bash
kubectl get pods -n petstore-demo backend-xxx -o yaml | grep image
```

**Expected**: Image should match node architecture (arm64)

**Fix**: Rebuild with multi-arch support:
```bash
./scripts/build-multiarch.sh
./scripts/deploy.sh
```

---

### Issue: "pull rate limit exceeded"

**Cause**: ECR/Docker Hub rate limiting

**Fix**: 
```bash
# Verify ECR login
aws ecr get-login-password --region eu-west-1 | docker login ...

# Rebuild and push
./scripts/build-multiarch.sh
```

---

### Issue: buildx not available

**Fix**:
```bash
# Install/enable buildx
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

---

## 📊 Architecture Support Matrix

| Image | Platform | Status |
|-------|----------|--------|
| backend | linux/amd64 | ✅ Included |
| backend | linux/arm64 | ✅ Included |
| frontend | linux/amd64 | ✅ Included |
| frontend | linux/arm64 | ✅ Included |

✅ This means your images work on:
- Your local laptop (amd64)
- AWS Graviton2 EKS nodes (arm64)
- Any other ARM64 or x86_64 system

---

## 🎓 Learning Points

> **Architecture Compatibility Rule**:
> - Docker images must match the target node's architecture
> - Multi-architecture images solve this by including both
> - ECR doesn't enforce architecture - K8s does
> - Always verify manifest when deploying to ARM64

---

## 🔗 References

- [Docker buildx documentation](https://docs.docker.com/build/architecture/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [AWS ECR](https://docs.aws.amazon.com/ecr/)
- [EKS + Graviton2](https://aws.amazon.com/blogs/aws/aws-graviton2-processor/)

---

## 🎯 Next Steps

1. ✅ Review changes in this document
2. ✅ Test with `./scripts/build-multiarch.sh` (if building locally)
3. ✅ Push to `main` for automatic CI/CD
4. ✅ Monitor pods: `kubectl get pods -n petstore-demo -w`
5. ✅ Check logs if needed: `kubectl logs -n petstore-demo -l app=backend -f`

**Result**: Multi-architecture images running successfully on ARM64 EKS! 🎉
