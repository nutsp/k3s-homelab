# Deployment Helm Chart

Helm chart สำหรับ deploy microservices บน Kubernetes cluster (k3s)

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Services](#services)
- [Usage](#usage)
- [Makefile Commands](#makefile-commands)
- [Health Checks](#health-checks)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

Chart นี้รองรับการ deploy หลาย services:
- **Auth Service**: Authentication service
- **Profile Service**: User profile service
- **Notification Job**: CronJob สำหรับส่ง notification

### Features

- ✅ Automatic pod restarts เมื่อ ConfigMap, Secret, หรือ image tag เปลี่ยน
- ✅ Health checks (liveness & readiness probes)
- ✅ Security context สำหรับ pod security
- ✅ Centralized Ingress configuration
- ✅ Resource limits และ requests
- ✅ Multiple environment support (dev, prod)
- ✅ Separate config และ service manifests

## 📦 Prerequisites

- Kubernetes cluster (k3s)
- Helm 3.x installed
- kubectl configured

### Install Helm

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 🚀 Installation

### Development Environment

```bash
# Generate manifests
make dev

# Deploy using Helm
make install

# หรือ deploy แบบ manual
kubectl apply -f kubernetes/dev/auth-config.yaml
kubectl apply -f kubernetes/dev/auth-service.yaml
kubectl apply -f kubernetes/dev/profile-config.yaml
kubectl apply -f kubernetes/dev/profile-service.yaml
kubectl apply -f kubernetes/dev/ingress-deploy.yaml
kubectl apply -f kubernetes/dev/notification-config.yaml
kubectl apply -f kubernetes/dev/notification-job.yaml
```

### Production Environment

```bash
# Generate manifests with production values
helm template app-deployment . --values values.yaml > production.yaml

# Deploy
helm install app-deployment . --values values.yaml --namespace app --create-namespace
```

## ⚙️ Configuration

### Values Files

- `values.yaml`: Default values สำหรับ production
- `values.dev.yaml`: Override values สำหรับ development

### Global Settings

```yaml
global:
  namespace: app  # Default namespace
```

### Service Configuration

แต่ละ service มี configuration ดังนี้:

```yaml
auth:
  enabled: true
  namespace: app
  replicas: 2
  image:
    repository: ghcr.io/k3s-homelab/auth
    tag: latest
    pullPolicy: Always
  service:
    name: auth-service
    type: ClusterIP
    port: 80
    targetPort: 80
  configmaps:
    virtual_server_enabled: "true"
  secrets:
    db_user: admin
    db_password: password
    db_host: localhost
    db_port: "5432"
    db_name: auth_db
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"
      cpu: "200m"
  # Health checks
  healthCheck:
    enabled: true
    livenessProbe:
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
  # Security context
  securityContext:
    enabled: true
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: false
    capabilities:
      drop:
        - ALL
```

## 🔧 Services

### Auth Service

Authentication service สำหรับจัดการ user authentication

**Endpoints:**
- Health: `GET /health`
- Ready: `GET /ready`

### Profile Service

User profile service สำหรับจัดการข้อมูล user profile

**Endpoints:**
- Health: `GET /health`
- Ready: `GET /ready`

### Notification Job

CronJob สำหรับส่ง notification ตาม schedule

**Configuration:**
```yaml
notificationJob:
  enabled: true
  schedule: "0 9 * * *"  # ทุกวันเวลา 09:00 น.
  concurrencyPolicy: Forbid
```

## 📝 Usage

### Generate Manifests

```bash
# Development
make dev

# Production
helm template app-deployment . --values values.yaml
```

### Deploy

```bash
# Using Helm (recommended)
make install

# หรือ
helm install app-deployment . --values values.dev.yaml --namespace app --create-namespace
```

### Upgrade

```bash
make upgrade

# หรือ
helm upgrade app-deployment . --values values.dev.yaml --namespace app
```

### Uninstall

```bash
make uninstall

# หรือ
helm uninstall app-deployment --namespace app
```

### Check Status

```bash
make status

# หรือ
helm status app-deployment --namespace app
kubectl get pods -n app
```

## 🛠️ Makefile Commands

```bash
make help          # แสดง help message
make dev           # Generate development manifests (default)
make dev-all       # Generate single deploy-all.yaml file
make lint          # Lint Helm chart
make dry-run       # Dry-run Helm install
make install       # Install Helm release
make upgrade       # Upgrade Helm release
make uninstall     # Uninstall Helm release
make status        # Check Helm release status
make validate      # Validate generated YAML files
make clean         # Clean generated files
make all           # Run lint, dry-run, and generate manifests
```

## 🏥 Health Checks

Chart นี้รองรับ health checks สำหรับทุก service:

### Liveness Probe

ตรวจสอบว่า pod ยังทำงานอยู่หรือไม่ หาก fail จะ restart pod

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Readiness Probe

ตรวจสอบว่า pod พร้อมรับ traffic หรือไม่ หาก fail จะ remove pod จาก service endpoints

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Disable Health Checks

```yaml
auth:
  healthCheck:
    enabled: false
```

## 🔒 Security

### Security Context

Chart นี้ใช้ security context เพื่อเพิ่มความปลอดภัย:

```yaml
securityContext:
  enabled: true
  runAsNonRoot: true      # ไม่รันเป็น root
  runAsUser: 1000          # รันเป็น user ID 1000
  fsGroup: 1000            # File system group
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  capabilities:
    drop:
      - ALL                # Drop all capabilities
```

### Secrets Management

⚠️ **Important**: อย่า commit secrets จริงใน values files

สำหรับ production ควรใช้:
- External secrets (e.g., Sealed Secrets, External Secrets Operator)
- Kubernetes Secrets ที่สร้างจาก CI/CD pipeline
- Vault integration

### Image Security

- ใช้ specific version tags แทน `latest`
- ใช้ image pull secrets สำหรับ private registries
- Scan images สำหรับ vulnerabilities

## 🔍 Troubleshooting

### Pod ไม่ restart เมื่อเปลี่ยน ConfigMap/Secret

Chart ใช้ checksum annotations เพื่อ trigger rolling update:

```yaml
annotations:
  checksum/configmap: {{ include "deployment.auth.configmap.checksum" . }}
  checksum/secret: {{ include "deployment.auth.secret.checksum" . }}
```

หาก pod ไม่ restart ให้ตรวจสอบ:
1. Checksum annotations ถูก update หรือไม่
2. Deployment rolling update strategy
3. Pod template hash

### Health Check Failures

```bash
# ตรวจสอบ pod logs
kubectl logs <pod-name> -n app

# ตรวจสอบ pod events
kubectl describe pod <pod-name> -n app

# Test health endpoint
kubectl exec -it <pod-name> -n app -- curl http://localhost:80/health
```

### Ingress ไม่ทำงาน

```bash
# ตรวจสอบ ingress
kubectl get ingress -n app
kubectl describe ingress -n app

# ตรวจสอบ Traefik
kubectl get pods -n kube-system | grep traefik
```

### Database Connection Issues

```bash
# ตรวจสอบ secrets
kubectl get secret auth-service-secrets -n app -o yaml

# ตรวจสอบ environment variables
kubectl exec -it <pod-name> -n app -- env | grep DB_
```

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [k3s Documentation](https://k3s.io/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `make lint` and `make dry-run`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

