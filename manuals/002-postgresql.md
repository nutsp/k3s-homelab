# คู่มือการติดตั้งและเสริมความปลอดภัย PostgreSQL (Ubuntu 22.04 LTS)

## 1. ข้อกำหนดเบื้องต้น
- OS: Ubuntu 22.04 LTS
- สิทธิ์: sudo user
- Network: แนะนำ Static IP
- เวลา: ตั้งค่า timezone ให้ถูกต้อง (`sudo timedatectl set-timezone Asia/Bangkok`)

## 2. เตรียมระบบพื้นฐาน
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg ufw
```

## 3. ติดตั้ง PostgreSQL จาก repo อย่างเป็นทางการ
```bash
# เพิ่ม GPG key และ repo
sudo install -d /usr/share/postgresql-common/pgdg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt update
sudo apt install -y postgresql-16 postgresql-client-16
```

เริ่มบริการและเช็คสถานะ:
```bash
sudo systemctl enable --now postgresql
sudo systemctl status postgresql
```

## 4. การตั้งค่าความปลอดภัยพื้นฐาน
### 4.1 สร้าง database user และ database
```bash
sudo -u postgres psql -c "CREATE ROLE appuser WITH LOGIN PASSWORD 'STRONG_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser ENCODING 'UTF8';"
```

### 4.2 เปลี่ยนรหัสผ่าน postgres superuser
```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'VERY_STRONG_PASSWORD';"
```

### 4.3 กำหนด pg_hba.conf (การยืนยันตัวตน)
ไฟล์: `/etc/postgresql/16/main/pg_hba.conf`
แนะนำใช้ `scram-sha-256` สำหรับ local และเครือข่ายภายในที่จำเป็นเท่านั้น

ตัวอย่าง minimal:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
# อนุญาต subnet ภายในตามต้องการ
# host  appdb          appuser         192.168.1.0/24          scram-sha-256
```

ปรับแล้ว reload:
```bash
sudo systemctl reload postgresql
```

### 4.4 บังคับใช้ scram-sha-256
ไฟล์: `/etc/postgresql/16/main/postgresql.conf`
```
password_encryption = scram-sha-256
```

### 4.5 เปิดใช้ SSL (self-signed อย่างน้อย)
```bash
sudo mkdir -p /etc/postgresql/16/main/ssl
sudo openssl req -new -x509 -days 3650 -nodes \
  -out /etc/postgresql/16/main/ssl/server.crt \
  -keyout /etc/postgresql/16/main/ssl/server.key \
  -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Homelab/OU=DB/CN=$(hostname -f)"
sudo chmod 600 /etc/postgresql/16/main/ssl/server.key
sudo chown postgres:postgres /etc/postgresql/16/main/ssl/server.*
```

แก้ไฟล์ `postgresql.conf`:
```
ssl = on
ssl_cert_file = 'ssl/server.crt'
ssl_key_file = 'ssl/server.key'
```
รีโหลด:
```bash
sudo systemctl reload postgresql
```

### 4.6 การรับฟังพอร์ต/ที่อยู่ (Listen Addresses)
ไฟล์ `postgresql.conf`:
```
listen_addresses = 'localhost'
# ถ้าต้องการรับจาก subnet ภายใน:
# listen_addresses = 'localhost,192.168.1.10'
```

### 4.7 ปิดการรันบน IPv6 ถ้าไม่ใช้ (ทางเลือก)
```
listen_addresses = '127.0.0.1'
```

### 4.8 Firewall (ufw)
```bash
sudo ufw allow proto tcp from 127.0.0.1 to any port 5432
# ถ้าต้องการอนุญาต subnet ภายใน:
# sudo ufw allow proto tcp from 192.168.1.0/24 to any port 5432
sudo ufw enable   # ถ้ายังไม่เปิด
sudo ufw status verbose
```

## 5. ค่าคอนฟิกที่แนะนำ (พื้นฐาน)
ไฟล์ `postgresql.conf`:
```
shared_buffers = 25% ของ RAM (เช่น 512MB บน RAM 2GB)
work_mem = 4MB            # ปรับตาม workload
maintenance_work_mem = 64MB
wal_level = replica       # ถ้าวางแผนทำ replication
max_wal_size = 1GB
min_wal_size = 80MB
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%a.log'
log_rotation_age = 1d
log_line_prefix = '%m [%p] %u@%d '
```
หลังปรับให้ reload หรือ restart:
```bash
sudo systemctl reload postgresql
# ถ้าปรับค่าที่ต้อง restart:
sudo systemctl restart postgresql
```

## 6. Backup & Restore
### 6.1 Logical Backup ด้วย pg_dump/pg_dumpall
```bash
# backup database เดียว
PGPASSWORD='STRONG_PASSWORD' pg_dump -h 127.0.0.1 -U appuser appdb > appdb_$(date +%F).sql

# backup ทั้ง cluster (roles + db)
sudo -u postgres pg_dumpall > cluster_$(date +%F).sql
```

### 6.2 Restore
```bash
psql -h 127.0.0.1 -U appuser -d appdb -f appdb_2025-01-01.sql
```

### 6.3 คำแนะนำ Backup
- เก็บ backup นอกเครื่องเดียวกับฐานข้อมูล
- เข้ารหัสไฟล์ backup (เช่น `gpg -c`)
- ทดสอบการ restore เป็นระยะ

## 7. การตรวจสอบและบำรุงรักษา
```bash
# สถานะ service
sudo systemctl status postgresql

# ดู connections
sudo -u postgres psql -c "SELECT datname, usename, client_addr, state FROM pg_stat_activity;"

# ดู disk usage ต่อ database
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"

# ดูตารางที่ใหญ่ที่สุด
sudo -u postgres psql -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;"
```

## 8. การถอดถอน (Uninstall)
```bash
sudo systemctl stop postgresql
sudo apt remove --purge -y postgresql-16 postgresql-client-16 postgresql-common
sudo rm -rf /etc/postgresql /var/lib/postgresql /var/log/postgresql
sudo apt autoremove -y
```

## 9. เช็กลิสต์ความปลอดภัยสรุป
- ใช้ `scram-sha-256` และตั้งรหัสผ่านยาก
- จำกัด `listen_addresses` ให้แคบที่สุด
- จำกัดการเข้าถึงผ่าน `pg_hba.conf` และ firewall
- เปิดใช้ SSL (อย่างน้อย self-signed; แนะนำใช้ cert ที่ trust ได้ถ้าเข้าถึงข้ามเครื่อง)
- เก็บและเข้ารหัส backup; ทดสอบการ restore
- เปิด log และทบทวน log สม่ำเสมอ
