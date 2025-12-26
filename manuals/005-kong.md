# คู่มือการติดตั้ง Kong API Gateway บน k3s

## 1. ข้อกำหนดเบื้องต้น

- **k3s Cluster**: ติดตั้งและทำงานอยู่แล้ว (ดูคู่มือ 001-k3s-cluster.md)
- **kubectl**: ตั้งค่าและใช้งานได้ (ไม่ต้องใช้ sudo)
- **Helm**: เวอร์ชัน 3.x หรือใหม่กว่า (แนะนำ)
- **Network**: k3s cluster พร้อม Traefik Ingress Controller (ติดตั้งอัตโนมัติ)
- **Storage**: PersistentVolume สำหรับ Kong database (PostgreSQL หรือ DB-less mode)

## 2. เตรียมระบบพื้นฐาน

### 2.1 ตรวจสอบ k3s Cluster

```bash
# ตรวจสอบ nodes
kubectl get nodes

# ตรวจสอบ pods ทั้งหมด
kubectl get pods --all-namespaces

# ตรวจสอบ Traefik Ingress Controller
kubectl get pods -n kube-system | grep traefik
```

### 2.2 ติดตั้ง Helm (ถ้ายังไม่มี)

```bash
# ดาวน์โหลดและติดตั้ง Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ตรวจสอบเวอร์ชัน
helm version

# เพิ่ม Kong Helm repository
helm repo add kong https://charts.konghq.com
helm repo update
```

### 2.3 สร้าง Namespace สำหรับ Kong

```bash
# สร้าง namespace
kubectl create namespace kong

# ตรวจสอบ
kubectl get namespaces
```

## 3. การติดตั้ง Kong

### 3.1 ติดตั้ง Kong ด้วย Helm (DB-less Mode - แนะนำสำหรับเริ่มต้น)

**DB-less mode** เหมาะสำหรับ:
- การทดสอบและพัฒนา
- ไม่ต้องการ database
- ใช้ declarative configuration

```bash
# ติดตั้ง Kong ใน DB-less mode
helm install kong kong/kong \
  --namespace kong \
  --set ingressController.enabled=true \
  --set env.database=off \
  --set env.declarative_config=/kong/declarative/kong.yml

# ตรวจสอบสถานะ
kubectl get pods -n kong
kubectl get svc -n kong
```

### 3.2 ติดตั้ง Kong ด้วย PostgreSQL Database (Production)

**PostgreSQL mode** เหมาะสำหรับ:
- Production environment
- ต้องการ dynamic configuration
- ต้องการ Kong Manager และ Developer Portal

#### 3.2.1 ติดตั้ง PostgreSQL (ถ้ายังไม่มี)

```bash
# สร้าง PostgreSQL deployment
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: kong
type: Opaque
stringData:
  password: STRONG_POSTGRES_PASSWORD_HERE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: kong
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: kong
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_USER
          value: kong
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: kong
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: kong
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
EOF

# รอให้ PostgreSQL พร้อม
kubectl wait --for=condition=ready pod -l app=postgres -n kong --timeout=300s
```

#### 3.2.2 ติดตั้ง Kong พร้อม PostgreSQL

```bash
# สร้าง Secret สำหรับ Kong database password
kubectl create secret generic kong-postgres-password \
  --from-literal=password=STRONG_POSTGRES_PASSWORD_HERE \
  -n kong

# ติดตั้ง Kong พร้อม PostgreSQL
helm install kong kong/kong \
  --namespace kong \
  --set ingressController.enabled=true \
  --set env.database=postgres \
  --set env.pg_host=postgres \
  --set env.pg_port=5432 \
  --set env.pg_user=kong \
  --set env.pg_password.valueFrom.secretKeyRef.name=kong-postgres-password \
  --set env.pg_password.valueFrom.secretKeyRef.key=password \
  --set env.pg_database=kong \
  --set postgresql.enabled=false

# ตรวจสอบสถานะ
kubectl get pods -n kong
kubectl get svc -n kong
```

### 3.3 ตรวจสอบการติดตั้ง

```bash
# ดู pods
kubectl get pods -n kong

# ดู services
kubectl get svc -n kong

# ดู logs
kubectl logs -n kong -l app=kong --tail=50

# ทดสอบ Kong Admin API
kubectl port-forward -n kong svc/kong-kong-proxy 8000:80 &
curl http://localhost:8000
```

## 4. การตั้งค่า Ingress สำหรับ Kong

### 4.1 สร้าง Ingress สำหรับ Kong Admin API

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kong-admin
  namespace: kong
  annotations:
    traefik.ingress.kubernetes.io/rule-type: PathPrefix
spec:
  ingressClassName: traefik
  rules:
  - host: kong-admin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kong-kong-admin
            port:
              number: 8001
EOF
```

### 4.2 สร้าง Ingress สำหรับ Kong Proxy

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kong-proxy
  namespace: kong
  annotations:
    traefik.ingress.kubernetes.io/rule-type: PathPrefix
spec:
  ingressClassName: traefik
  rules:
  - host: api.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kong-kong-proxy
            port:
              number: 80
EOF
```

### 4.3 ตรวจสอบ Ingress

```bash
# ดู Ingress ทั้งหมด
kubectl get ingress -n kong

# ดูรายละเอียด
kubectl describe ingress kong-proxy -n kong
```

## 5. การตั้งค่าความปลอดภัย Kong

### 5.1 ตั้งค่า Admin API Access Control

```bash
# แก้ไข Kong deployment เพื่อจำกัด Admin API
kubectl patch deployment kong-kong -n kong --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "KONG_ADMIN_LISTEN",
      "value": "127.0.0.1:8001"
    }
  }
]'
```

### 5.2 ตั้งค่า Proxy Listen Address

```bash
# ตั้งค่าให้ Proxy รับเฉพาะจาก internal network
kubectl patch deployment kong-kong -n kong --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "KONG_PROXY_LISTEN",
      "value": "0.0.0.0:8000"
    }
  }
]'
```

### 5.3 สร้าง Admin API Service (Internal Only)

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kong-admin-internal
  namespace: kong
spec:
  type: ClusterIP
  selector:
    app: kong
  ports:
  - port: 8001
    targetPort: 8001
EOF
```

### 5.4 ตั้งค่า Authentication Plugin

```bash
# สร้าง API Key สำหรับ Admin API
kubectl exec -it -n kong deployment/kong-kong -- \
  kong config db_import /dev/stdin <<EOF
_format_version: "3.0"
consumers:
- username: admin
  keyauth_credentials:
  - key: YOUR_ADMIN_API_KEY_HERE
EOF
```

## 6. การทดสอบการทำงาน

### 6.1 ทดสอบ Kong Proxy

```bash
# ทดสอบผ่าน port-forward
kubectl port-forward -n kong svc/kong-kong-proxy 8000:80

# ใน terminal อื่น
curl -i http://localhost:8000
```

### 6.2 ทดสอบ Kong Admin API

```bash
# ทดสอบ Admin API
kubectl port-forward -n kong svc/kong-kong-admin 8001:8001

# ใน terminal อื่น
curl http://localhost:8001/
curl http://localhost:8001/services
```

### 6.3 สร้าง Service และ Route ทดสอบ

```bash
# สร้าง Service ทดสอบ
curl -i http://localhost:8001/services \
  --data "name=example-service" \
  --data "url=http://httpbin.org"

# สร้าง Route
curl -i http://localhost:8001/services/example-service/routes \
  --data "hosts[]=example.com"

# ทดสอบ Route
curl -i http://localhost:8000/ \
  -H "Host: example.com"
```

## 7. การตั้งค่าขั้นสูง

### 7.1 ตั้งค่า Kong ด้วย Declarative Config (DB-less)

สร้างไฟล์ `kong-config.yml`:

```yaml
_format_version: "3.0"

services:
- name: example-service
  url: http://httpbin.org
  routes:
  - name: example-route
    hosts:
    - example.com
    paths:
    - /

plugins:
- name: rate-limiting
  config:
    minute: 5
    hour: 100
```

สร้าง ConfigMap:

```bash
kubectl create configmap kong-config \
  --from-file=kong.yml=kong-config.yml \
  -n kong

# อัปเดต Kong deployment เพื่อใช้ config
helm upgrade kong kong/kong \
  --namespace kong \
  --set env.database=off \
  --set env.declarative_config=/kong/declarative/kong.yml \
  --set-file dblessConfig.config=kong-config.yml
```

### 7.2 ตั้งค่า Kong Manager (Enterprise)

```bash
# สำหรับ Kong Enterprise
helm install kong kong/kong \
  --namespace kong \
  --set enterprise.enabled=true \
  --set enterprise.license.value="YOUR_LICENSE_KEY" \
  --set env.admin_gui_url=http://kong-manager.local \
  --set env.admin_api_uri=http://kong-admin.local
```

### 7.3 ตั้งค่า High Availability

```bash
# ติดตั้ง Kong พร้อม multiple replicas
helm upgrade kong kong/kong \
  --namespace kong \
  --set replicaCount=3 \
  --set ingressController.replicaCount=2
```

### 7.4 ตั้งค่า Resource Limits

```bash
# อัปเดต resource limits
helm upgrade kong kong/kong \
  --namespace kong \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi
```

## 8. การจัดการและ Monitoring

### 8.1 คำสั่งที่มีประโยชน์

```bash
# ดู pods
kubectl get pods -n kong

# ดู services
kubectl get svc -n kong

# ดู logs
kubectl logs -n kong -l app=kong --tail=100 -f

# ดู events
kubectl get events -n kong --sort-by='.lastTimestamp'

# เข้าถึง Kong pod
kubectl exec -it -n kong deployment/kong-kong -- /bin/sh

# ทดสอบ Kong configuration
kubectl exec -it -n kong deployment/kong-kong -- kong config -c /kong/kong.conf parse
```

### 8.2 Monitoring Kong Metrics

```bash
# เปิดใช้งาน Prometheus plugin
curl -i http://localhost:8001/services/example-service/plugins \
  --data "name=prometheus"

# ดู metrics
curl http://localhost:8001/metrics
```

### 8.3 ดู Kong Status

```bash
# ดู Kong status
curl http://localhost:8001/status

# ดู Kong cluster status (ถ้าใช้ database mode)
curl http://localhost:8001/cluster
```

## 9. Security Best Practices

### 9.1 Checklist ความปลอดภัย

- [x] จำกัด Admin API access (ใช้ ClusterIP หรือ bind ที่ 127.0.0.1)
- [x] ใช้ strong password สำหรับ PostgreSQL
- [x] เปิดใช้งาน authentication plugins (key-auth, oauth2, jwt)
- [x] ตั้งค่า rate limiting
- [x] ใช้ HTTPS/TLS สำหรับ production
- [x] จำกัด network access ผ่าน firewall
- [x] ใช้ RBAC สำหรับ Kubernetes
- [x] ตั้งค่า resource limits
- [x] เปิดใช้งาน audit logging
- [x] อัปเดต Kong เป็นประจำ

### 9.2 ตั้งค่า TLS/SSL

```bash
# สร้าง TLS certificate
kubectl create secret tls kong-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n kong

# อัปเดต Ingress เพื่อใช้ TLS
kubectl patch ingress kong-proxy -n kong --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/tls",
    "value": [
      {
        "hosts": ["api.local"],
        "secretName": "kong-tls"
      }
    ]
  }
]'
```

### 9.3 ตั้งค่า Rate Limiting

```bash
# สร้าง rate limiting plugin
curl -i http://localhost:8001/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=5" \
  --data "config.hour=100"
```

## 10. Troubleshooting

### 10.1 ปัญหาที่พบบ่อย

**Kong pods ไม่สามารถ start ได้**:

```bash
# ตรวจสอบ logs
kubectl logs -n kong -l app=kong --tail=100

# ตรวจสอบ events
kubectl describe pod -n kong -l app=kong

# ตรวจสอบ PostgreSQL connection (ถ้าใช้ database mode)
kubectl exec -it -n kong deployment/kong-kong -- \
  nc -zv postgres.kong.svc.cluster.local 5432
```

**Kong ไม่สามารถเชื่อมต่อกับ PostgreSQL**:

```bash
# ตรวจสอบ PostgreSQL service
kubectl get svc -n kong postgres

# ตรวจสอบ PostgreSQL logs
kubectl logs -n kong -l app=postgres

# ทดสอบ connection
kubectl exec -it -n kong deployment/kong-kong -- \
  psql -h postgres.kong.svc.cluster.local -U kong -d kong
```

**Ingress ไม่ทำงาน**:

```bash
# ตรวจสอบ Traefik
kubectl get pods -n kube-system | grep traefik

# ตรวจสอบ Ingress
kubectl describe ingress kong-proxy -n kong

# ตรวจสอบ Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=100
```

**Kong Admin API ไม่สามารถเข้าถึงได้**:

```bash
# ตรวจสอบ service
kubectl get svc -n kong kong-kong-admin

# ทดสอบผ่าน port-forward
kubectl port-forward -n kong svc/kong-kong-admin 8001:8001

# ตรวจสอบ firewall rules
```

### 10.2 Performance Tuning

```bash
# เพิ่ม worker processes
helm upgrade kong kong/kong \
  --namespace kong \
  --set env.nginx_worker_processes=auto

# เพิ่ม worker connections
helm upgrade kong kong/kong \
  --namespace kong \
  --set env.nginx_worker_connections=16384

# เพิ่ม memory cache
helm upgrade kong kong/kong \
  --namespace kong \
  --set env.memory_cache_size=128m
```

### 10.3 Debug Mode

```bash
# เปิด debug logging
helm upgrade kong kong/kong \
  --namespace kong \
  --set env.log_level=debug

# ดู debug logs
kubectl logs -n kong -l app=kong --tail=200 -f
```

## 11. การถอนการติดตั้ง

```bash
# ลบ Kong deployment
helm uninstall kong -n kong

# ลบ namespace (จะลบทุกอย่างใน namespace)
kubectl delete namespace kong

# หรือลบทีละ resource
kubectl delete ingress -n kong --all
kubectl delete svc -n kong --all
kubectl delete deployment -n kong --all
kubectl delete pvc -n kong --all
```

## 12. หมายเหตุเพิ่มเติม

- Kong Ingress Controller จะจัดการ Ingress resources อัตโนมัติ
- สำหรับ production, ควรใช้ PostgreSQL database mode
- DB-less mode เหมาะสำหรับการทดสอบและ development
- Kong สามารถทำงานร่วมกับ Traefik ได้ (Traefik เป็น Ingress, Kong เป็น API Gateway)
- ตรวจสอบ Kong version: `curl http://localhost:8001/`
- สำหรับ high availability, ใช้ multiple replicas และ PostgreSQL replication
- ควรทำ backup database เป็นประจำ (ถ้าใช้ database mode)
- Kong Enterprise มี features เพิ่มเติม เช่น Kong Manager, Developer Portal, RBAC

## 13. การใช้งานร่วมกับ Traefik

ตามสถาปัตยกรรมที่ระบุใน `gateway/README.md`:

```
Client → Traefik (Ingress) → Kong (API Gateway) → Backend Services
```

### 13.1 สร้าง Ingress ที่ชี้ไปยัง Kong

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kong-gateway
  namespace: kong
  annotations:
    traefik.ingress.kubernetes.io/rule-type: PathPrefix
spec:
  ingressClassName: traefik
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kong-kong-proxy
            port:
              number: 80
EOF
```

### 13.2 สร้าง Backend Service และ Route ใน Kong

```bash
# สร้าง Service ใน Kong
curl -i http://localhost:8001/services \
  --data "name=backend-service" \
  --data "url=http://backend-service.default.svc.cluster.local:80"

# สร้าง Route
curl -i http://localhost:8001/services/backend-service/routes \
  --data "hosts[]=api.example.com" \
  --data "paths[]=/api"
```

### 13.3 ทดสอบ Flow ทั้งหมด

```bash
# ทดสอบผ่าน Traefik → Kong → Backend
curl -H "Host: api.example.com" http://<TRAEFIK_IP>/api
```

