# คู่มือการติดตั้ง k3s Cluster

## 0. การเตรียมความพร้อมเบื้องต้น

### 0.1 ความต้องการของระบบ

- **OS**: Ubuntu 22.04 LTS (แนะนำ) หรือ Ubuntu 20.04 LTS
- **RAM**: อย่างน้อย 512MB สำหรับ master node, 256MB สำหรับ worker node
- **CPU**: อย่างน้อย 1 core
- **Network**: Static IP (แนะนำ) เพื่อความเสถียรของ cluster
- **Firewall**: เปิดพอร์ตที่จำเป็น (6443, 10250, 8472/UDP สำหรับ Flannel)

### 0.2 การตั้งค่าพื้นฐาน

อัปเดตระบบและตั้งค่า timezone:

```bash
sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone Asia/Bangkok
```

ตรวจสอบ timezone:

```bash
timedatectl
```

### 0.3 ปิดการใช้งาน Swap

**สำคัญ**: k3s ต้องการให้ปิด swap เพื่อให้ Kubernetes ทำงานได้อย่างถูกต้อง

```bash
# ปิด swap ชั่วคราว
sudo swapoff -a

# ปิด swap ถาวรโดยการ comment ใน /etc/fstab
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ตรวจสอบว่า swap ถูกปิดแล้ว
free -h
```

### 0.4 การตั้งค่า Firewall (ถ้ามี)

ถ้าใช้ `ufw`:

```bash
# บน Master Node
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp

# บน Worker Node
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp
```

---

## 1. การติดตั้ง k3s Cluster

### 1.1 ติดตั้ง k3s Master Node

รันคำสั่งต่อไปนี้บนเครื่องที่จะเป็น master node:

```bash
curl -sfL https://get.k3s.io | sh -
```

**หมายเหตุ**: การติดตั้งนี้จะ:
- ติดตั้ง k3s เป็น systemd service
- เริ่มต้น k3s อัตโนมัติ
- ติดตั้ง kubectl และ k3s utilities

**ตรวจสอบสถานะการติดตั้ง**:

```bash
# ตรวจสอบว่า service ทำงานอยู่
sudo systemctl status k3s

# ตรวจสอบ nodes
sudo kubectl get nodes

# ดูข้อมูลเพิ่มเติม
sudo kubectl get nodes -o wide
```

**ดู Token สำหรับ Worker Nodes**:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

**บันทึก Token นี้ไว้** - จะใช้สำหรับการเชื่อมต่อ worker nodes

**ดู Master Node IP**:

```bash
# ดู IP address
ip addr show

# หรือ
hostname -I
```

### 1.2 ติดตั้ง Worker Nodes

บนเครื่องที่จะเป็น worker node, แทนค่า `<MASTER-IP>` และ `<TOKEN>` ด้วยค่าจริง:

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://<MASTER-IP>:6443 \
K3S_TOKEN=<TOKEN> sh -
```

**ตัวอย่าง**:

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://192.168.1.100:6443 \
K3S_TOKEN=K10abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567 sh -
```

**ตรวจสอบสถานะบน Worker Node**:

```bash
sudo systemctl status k3s-agent
```

**ตรวจสอบจาก Master Node**:

```bash
sudo kubectl get nodes
```

ควรเห็นทั้ง master และ worker nodes พร้อมสถานะ `Ready`

### 1.3 ตั้งค่า kubectl สำหรับผู้ใช้ปกติ

**สำคัญ**: เพื่อให้สามารถใช้ `kubectl` ได้โดยไม่ต้องใช้ `sudo`

```bash
# สร้าง directory สำหรับ kubeconfig
mkdir -p ~/.kube

# คัดลอก config file
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# เปลี่ยน ownership
sudo chown $(id -u):$(id -g) ~/.kube/config

# ตั้งค่า permissions
chmod 600 ~/.kube/config
```

**แก้ไข config สำหรับการเข้าถึงจากเครื่องอื่น** (ถ้าต้องการ):

```bash
# แก้ไข server address จาก localhost เป็น IP จริง
sed -i 's/127.0.0.1/<MASTER-IP>/g' ~/.kube/config
```

**ทดสอบการใช้งาน**:

```bash
# ตรวจสอบ nodes
kubectl get nodes

# ตรวจสอบ pods
kubectl get pods --all-namespaces

# ตรวจสอบ cluster info
kubectl cluster-info
```

---

## 2. การตรวจสอบและ Troubleshooting

### 2.1 ตรวจสอบสถานะ Cluster

```bash
# ดู nodes ทั้งหมด
kubectl get nodes -o wide

# ดู pods ทั้งหมด
kubectl get pods --all-namespaces

# ดู services
kubectl get svc --all-namespaces

# ดู logs ของ k3s service
sudo journalctl -u k3s -f
```

### 2.2 Troubleshooting ทั่วไป

**Worker node ไม่สามารถเชื่อมต่อกับ master**:

1. ตรวจสอบว่า master node เปิดพอร์ต 6443
2. ตรวจสอบ firewall rules
3. ตรวจสอบ network connectivity: `ping <MASTER-IP>`
4. ตรวจสอบ logs: `sudo journalctl -u k3s-agent -f`

**kubectl ไม่ทำงาน**:

1. ตรวจสอบว่า config file ถูกต้อง: `cat ~/.kube/config`
2. ตรวจสอบ permissions: `ls -la ~/.kube/config`
3. ลองใช้ `sudo kubectl` เพื่อทดสอบ

**ลบ Worker Node ออกจาก Cluster**:

```bash
# บน worker node
sudo /usr/local/bin/k3s-agent-uninstall.sh

# หรือ
sudo systemctl stop k3s-agent
sudo systemctl disable k3s-agent
```

**ลบ Master Node**:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 3. คำสั่งที่มีประโยชน์

### 3.1 การจัดการ k3s Service

```bash
# เริ่ม service
sudo systemctl start k3s

# หยุด service
sudo systemctl stop k3s

# รีสตาร์ท service
sudo systemctl restart k3s

# ดู logs
sudo journalctl -u k3s -f
```

### 3.2 การจัดการ Cluster

```bash
# ดู cluster info
kubectl cluster-info

# ดู version
kubectl version

# ดู resources ทั้งหมด
kubectl get all --all-namespaces
```

---

## 4. หมายเหตุเพิ่มเติม

- k3s จะติดตั้ง Traefik เป็น default ingress controller
- k3s จะติดตั้ง local-path-provisioner สำหรับ storage
- ไฟล์ config อยู่ที่ `/etc/rancher/k3s/k3s.yaml`
- kubeconfig สำหรับ root user อยู่ที่ `/etc/rancher/k3s/k3s.yaml`
- สำหรับ production, ควรพิจารณาใช้ external database แทน SQLite

