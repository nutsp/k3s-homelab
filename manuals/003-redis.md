# คู่มือการติดตั้งและเสริมความปลอดภัย Redis (Ubuntu 22.04 LTS)

## 1. ข้อกำหนดเบื้องต้น

- **OS**: Ubuntu 22.04 LTS
- **สิทธิ์**: sudo user
- **Network**: แนะนำ Static IP
- **RAM**: อย่างน้อย 512MB (แนะนำ 1GB+)
- **เวลา**: ตั้งค่า timezone ให้ถูกต้อง (`sudo timedatectl set-timezone Asia/Bangkok`)

## 2. เตรียมระบบพื้นฐาน

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg ufw build-essential
```

## 3. ติดตั้ง Redis

### 3.1 ติดตั้งจาก Ubuntu Repository

```bash
sudo apt install -y redis-server
```

### 3.2 ติดตั้งจาก Source (สำหรับเวอร์ชันล่าสุด)

```bash
# ดาวน์โหลดและ compile จาก source
cd /tmp
curl -fsSL https://download.redis.io/redis-stable.tar.gz -o redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
sudo make install

# สร้าง systemd service
sudo mkdir -p /etc/redis /var/lib/redis /var/log/redis
sudo useradd --system --home /var/lib/redis --shell /bin/false redis
sudo chown redis:redis /var/lib/redis /var/log/redis
```

## 4. การตั้งค่าความปลอดภัย Redis

### 4.1 ตั้งค่า Redis Configuration

แก้ไขไฟล์ `/etc/redis/redis.conf` (หรือ `/etc/redis.conf`):

```bash
sudo nano /etc/redis/redis.conf
```

**การตั้งค่าความปลอดภัยที่สำคัญ**:

```conf
# 1. เปลี่ยน bind address - อย่า bind ที่ 0.0.0.0 ถ้าไม่จำเป็น
# สำหรับ localhost only:
bind 127.0.0.1

# สำหรับ network access (ระวัง!):
# bind 192.168.1.100

# 2. ปิดการใช้งานคำสั่งอันตราย
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command SHUTDOWN SHUTDOWN_SECURE
rename-command DEBUG ""

# 3. ตั้งค่า password (AUTH)
requirepass YOUR_STRONG_REDIS_PASSWORD_HERE

# 4. ปิดการใช้งาน protected mode (ถ้าใช้ password)
protected-mode yes

# 5. ตั้งค่า timeout สำหรับ idle connections
timeout 300

# 6. จำกัด max clients
maxclients 10000

# 7. ตั้งค่า memory limit และ eviction policy
maxmemory 2gb
maxmemory-policy allkeys-lru

# 8. เปิดใช้งาน AOF persistence (แนะนำ)
appendonly yes
appendfsync everysec

# 9. ตั้งค่า log level
loglevel notice

# 10. ตั้งค่า log file
logfile /var/log/redis/redis-server.log

# 11. ตั้งค่า working directory
dir /var/lib/redis
```

### 4.2 ตั้งค่า Systemd Service

ตรวจสอบไฟล์ `/etc/systemd/system/redis.service`:

```ini
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/bin/redis-cli shutdown
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 4.3 ตั้งค่า Firewall

```bash
# ถ้า Redis ต้องใช้จากเครื่องอื่น (ระวังความปลอดภัย!)
# sudo ufw allow from 192.168.1.0/24 to any port 6379

# สำหรับ localhost only (แนะนำ):
# ไม่ต้องเปิด port 6379 ใน firewall
```

### 4.4 เริ่มบริการและตรวจสอบ

```bash
# Reload systemd
sudo systemctl daemon-reload

# เริ่มบริการ
sudo systemctl enable --now redis-server

# ตรวจสอบสถานะ
sudo systemctl status redis-server

# ตรวจสอบ logs
sudo journalctl -u redis-server -f
```

## 5. การทดสอบการเชื่อมต่อ

### 5.1 ทดสอบด้วย redis-cli (Local)

```bash
# เชื่อมต่อและ authenticate
redis-cli
AUTH YOUR_STRONG_REDIS_PASSWORD_HERE

# ทดสอบคำสั่ง
PING
# ควรได้: PONG

SET test "Hello Redis"
GET test
# ควรได้: "Hello Redis"

INFO server
```

### 5.2 ทดสอบด้วย redis-cli (Remote)

```bash
redis-cli -h <REDIS_IP> -p 6379 -a YOUR_STRONG_REDIS_PASSWORD_HERE
```

### 5.3 ทดสอบด้วย Python

```python
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='YOUR_STRONG_REDIS_PASSWORD_HERE',
    decode_responses=True
)

# ทดสอบ
r.set('test', 'Hello Redis')
print(r.get('test'))
```

## 6. การตั้งค่าขั้นสูง

### 6.1 Redis Sentinel (High Availability)

สำหรับ production, ควรใช้ Redis Sentinel หรือ Redis Cluster:

```bash
# ติดตั้ง Redis Sentinel
sudo apt install -y redis-sentinel

# แก้ไขไฟล์ /etc/redis/sentinel.conf
sudo nano /etc/redis/sentinel.conf
```

### 6.2 Redis Persistence

**RDB (Snapshot)**:
```conf
# ใน redis.conf
save 900 1      # save ถ้ามีการเปลี่ยนแปลงอย่างน้อย 1 key ใน 900 วินาที
save 300 10     # save ถ้ามีการเปลี่ยนแปลงอย่างน้อย 10 keys ใน 300 วินาที
save 60 10000   # save ถ้ามีการเปลี่ยนแปลงอย่างน้อย 10000 keys ใน 60 วินาที
```

**AOF (Append Only File)**:
```conf
appendonly yes
appendfsync everysec  # everysec, always, หรือ no
```

### 6.3 Memory Management

```conf
# ตั้งค่า max memory
maxmemory 2gb

# Eviction policies:
# - noeviction: ไม่ลบข้อมูล (default)
# - allkeys-lru: ลบ keys ที่ใช้ไม่บ่อย
# - volatile-lru: ลบ keys ที่มี expire time ที่ใช้ไม่บ่อย
# - allkeys-random: ลบ keys แบบสุ่ม
# - volatile-random: ลบ keys ที่มี expire time แบบสุ่ม
# - volatile-ttl: ลบ keys ที่ expire เร็วที่สุด
maxmemory-policy allkeys-lru
```

## 7. การจัดการและ Monitoring

### 7.1 คำสั่งที่มีประโยชน์

```bash
# ดูข้อมูลสถิติ
redis-cli -a YOUR_PASSWORD INFO

# ดูข้อมูล memory
redis-cli -a YOUR_PASSWORD INFO memory

# ดูข้อมูล clients
redis-cli -a YOUR_PASSWORD INFO clients

# ดู keys ทั้งหมด (ระวัง! อาจช้า)
redis-cli -a YOUR_PASSWORD KEYS *

# นับจำนวน keys
redis-cli -a YOUR_PASSWORD DBSIZE

# ดูข้อมูล config
redis-cli -a YOUR_PASSWORD CONFIG GET "*"

# Flush database (ระวัง!)
redis-cli -a YOUR_PASSWORD FLUSHDB
```

### 7.2 Monitoring Tools

```bash
# ติดตั้ง redis-tools
sudo apt install -y redis-tools

# ใช้ redis-cli monitor (ระวัง performance impact)
redis-cli -a YOUR_PASSWORD MONITOR

# ใช้ redis-cli --latency
redis-cli -a YOUR_PASSWORD --latency
```

### 7.3 Backup และ Restore

**Backup (RDB)**:
```bash
# RDB file อยู่ที่ /var/lib/redis/dump.rdb
sudo cp /var/lib/redis/dump.rdb /backup/redis-dump-$(date +%Y%m%d).rdb
```

**Backup (AOF)**:
```bash
# AOF file อยู่ที่ /var/lib/redis/appendonly.aof
sudo cp /var/lib/redis/appendonly.aof /backup/redis-aof-$(date +%Y%m%d).aof
```

**Restore**:
```bash
# หยุด Redis
sudo systemctl stop redis-server

# คัดลอก backup file
sudo cp /backup/redis-dump-YYYYMMDD.rdb /var/lib/redis/dump.rdb
sudo chown redis:redis /var/lib/redis/dump.rdb

# เริ่ม Redis
sudo systemctl start redis-server
```

## 8. Security Best Practices

### 8.1 Checklist ความปลอดภัย

- [x] ตั้งค่า `requirepass` (password)
- [x] เปลี่ยน `bind` address (ไม่ใช้ 0.0.0.0)
- [x] เปิดใช้งาน `protected-mode`
- [x] ปิดการใช้งานคำสั่งอันตราย (FLUSHDB, FLUSHALL, CONFIG)
- [x] ตั้งค่า firewall rules
- [x] ใช้ TLS/SSL สำหรับ remote connections (ถ้า Redis 6+)
- [x] จำกัด network access
- [x] ตั้งค่า `maxmemory` และ eviction policy
- [x] ใช้ user ที่ไม่ใช่ root สำหรับ Redis process
- [x] ตั้งค่า file permissions ที่เหมาะสม

### 8.2 TLS/SSL Configuration (Redis 6+)

```conf
# ใน redis.conf
port 0
tls-port 6380
tls-cert-file /etc/redis/redis.crt
tls-key-file /etc/redis/redis.key
tls-ca-cert-file /etc/redis/ca.crt
tls-auth-clients yes
```

### 8.3 ACL (Access Control List) - Redis 6+

```bash
# สร้าง user พร้อม permissions
redis-cli -a YOUR_PASSWORD ACL SETUSER appuser on >apppassword ~* &* +@read +@write -@dangerous

# ใช้ ACL แทน password
redis-cli --user appuser --pass apppassword
```

## 9. Troubleshooting

### 9.1 ปัญหาที่พบบ่อย

**Redis ไม่สามารถ start ได้**:
```bash
# ตรวจสอบ logs
sudo journalctl -u redis-server -n 50

# ตรวจสอบ config syntax
redis-server /etc/redis/redis.conf --test-memory 1
```

**Connection refused**:
```bash
# ตรวจสอบว่า Redis ทำงานอยู่
sudo systemctl status redis-server

# ตรวจสอบ port
sudo netstat -tlnp | grep 6379
```

**Memory issues**:
```bash
# ตรวจสอบ memory usage
redis-cli -a YOUR_PASSWORD INFO memory

# ตรวจสอบ eviction policy
redis-cli -a YOUR_PASSWORD CONFIG GET maxmemory-policy
```

### 9.2 Performance Tuning

```conf
# ใน redis.conf
# ปรับ TCP backlog
tcp-backlog 511

# ปรับ timeout
timeout 300

# ปรับ TCP keepalive
tcp-keepalive 300

# ปรับ max clients
maxclients 10000
```

## 10. การถอนการติดตั้ง

```bash
# หยุดและปิดการใช้งาน service
sudo systemctl stop redis-server
sudo systemctl disable redis-server

# ลบ package
sudo apt remove --purge redis-server redis-tools

# ลบ config และ data (ระวัง!)
sudo rm -rf /etc/redis
sudo rm -rf /var/lib/redis
sudo rm -rf /var/log/redis
```

## 11. หมายเหตุเพิ่มเติม

- Redis เป็น in-memory database - ข้อมูลจะหายถ้า server restart (ถ้าไม่เปิด persistence)
- สำหรับ production, ควรใช้ Redis Sentinel หรือ Redis Cluster
- ตรวจสอบ Redis version: `redis-cli -a YOUR_PASSWORD INFO server | grep redis_version`
- สำหรับ high availability, พิจารณาใช้ Redis Enterprise หรือ managed service
- ควรทำ backup เป็นประจำ โดยเฉพาะถ้าใช้ persistence

