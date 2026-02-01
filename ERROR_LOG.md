# ERROR_LOG

This file records errors encountered while working on the project and the resolutions applied.

Purpose
- Provide a single, human-readable source of truth for errors encountered during development, builds, deployments, and runtime.

How to use
- Use the helper script `scripts/log_error.sh` to append error entries quickly.
- When an error is resolved, update the corresponding entry: fill in **Root cause**, **Fix applied**, set **Status:** Resolved, and add **Resolved date**.

Template (one entry per error)

---

## [2026-02-01 12:00:00 UTC] exec format error: Wrong CPU Architecture in Docker Images

- **Environment:** prod (EKS)
- **Status:** Resolved
- **Steps to reproduce:**
  1. Build Docker images targeting `linux/amd64`
  2. Push to ECR
  3. Deploy to EKS cluster
  4. Check pod logs: `kubectl logs -f <pod-name>`
- **Error output / Stack trace:**
```
exec /usr/local/bin/gunicorn: exec format error
exec /usr/local/bin/python: exec format error
```
- **Root cause:**
  - EKS cluster nodes are **aarch64 (arm64)** CPU architecture
  - Built Docker images for **amd64** instead of **arm64**
  - Binary mismatch causes kernel to fail execution
  - Verified with: `kubectl get nodes -o wide` → kernel line shows `aarch64`
- **Fix applied:**
  - Updated CI/CD workflow to build for `linux/arm64` instead of `linux/amd64`
  - Built and pushed arm64 images to ECR:
    - `024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/petstore-backend:latest` (arm64)
    - `024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/petstore-frontend:latest` (arm64)
  - Restarted K8s deployments to pull new images
- **Files changed:**
  - `.github/workflows/ci-cd.yml` - Changed `platforms: linux/amd64,linux/amd64` → `platforms: linux/arm64`
  - `backend/requirements.txt` - Relaxed Werkzeug version constraint to `>=2.3.0` (multi-arch compatibility)
- **Notes:**
  - Always verify EKS node architecture with `kubectl get nodes -o wide` before building images
  - Use `uname -m` or `kubectl describe node <name>` for architecture confirmation
  - Cross-compilation issues can occur when building for arm64 on amd64 host (and vice versa)
- **Resolved date:** 2026-02-01

---

## [2026-02-01 12:15:00 UTC] ImagePullBackOff: Missing ECR Authentication Secret

- **Environment:** prod (EKS)
- **Status:** Resolved
- **Steps to reproduce:**
  1. Update K8s deployment to use ECR image
  2. Apply manifests without imagePullSecrets
  3. Pods stay in ImagePullBackOff state
- **Error output / Stack trace:**
```
Warning  Failed     15s  kubelet  Failed to pull image "024848484634.dkr.ecr.eu-west-1.amazonaws.com/ayan-warsame/petstore-backend:latest": rpc error: code = Unauthenticated desc = no basic auth credentials
```
- **Root cause:**
  - EKS cluster had no credentials to authenticate with ECR private registry
  - K8s deployment specs were missing `imagePullSecrets` field
  - Even with ECR IAM roles, explicit K8s secrets needed for image pull
- **Fix applied:**
  - Created K8s secret for ECR authentication: `kubectl create secret docker-registry ecr-secret ...`
  - Added `imagePullSecrets` to both backend and frontend K8s deployment specs
  - Changed `imagePullPolicy` from `IfNotPresent` to `Always` to force refresh on each deployment
- **Files changed:**
  - `k8s/backend-deployment.yaml` - Added imagePullSecrets, corrected image name from `backend:latest` to `petstore-backend:latest`
  - `k8s/frontend-deployment.yaml` - Added imagePullSecrets, corrected image name from `frontend:latest` to `petstore-frontend:latest`
- **Notes:**
  - ECR secret must be created in the same namespace as the deployment
  - Password from `aws ecr get-login-password` expires after 12 hours; refresh if pulls fail
  - Verify secret exists: `kubectl get secrets -n petstore-demo`
- **Resolved date:** 2026-02-01

---
