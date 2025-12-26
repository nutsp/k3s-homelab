# คู่มือการติดตั้งและเสริมความปลอดภัย RabbitMQ (Ubuntu 22.04 LTS)

## 1. ข้อกำหนดเบื้องต้น

- **OS**: Ubuntu 22.04 LTS
- **สิทธิ์**: sudo user
- **Network**: แนะนำ Static IP
- **RAM**: อย่างน้อย 512MB (แนะนำ 1GB+)
- **เวลา**: ตั้งค่า timezone ให้ถูกต้อง (`sudo timedatectl set-timezone Asia/Bangkok`)
- **Erlang**: RabbitMQ ต้องการ Erlang/OTP (จะติดตั้งอัตโนมัติ)

## 2. เตรียมระบบพื้นฐาน

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg ufw wget
```

## 3. ติดตั้ง RabbitMQ

### 3.1 เพิ่ม RabbitMQ Repository

```bash
# เพิ่ม GPG key
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null

# เพิ่ม repository
echo "deb [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/ubuntu jammy main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
echo "deb [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/ubuntu jammy main" | sudo tee -a /etc/apt/sources.list.d/rabbitmq.list

# อัปเดต package list
sudo apt update
```

### 3.2 ติดตั้ง Erlang และ RabbitMQ

```bash
# ติดตั้ง Erlang และ RabbitMQ
sudo apt install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl rabbitmq-server

# หรือติดตั้งเฉพาะ RabbitMQ (จะติดตั้ง Erlang dependencies อัตโนมัติ)
sudo apt install -y rabbitmq-server
```

### 3.3 เริ่มบริการและตรวจสอบ

```bash
# เริ่มบริการ
sudo systemctl enable --now rabbitmq-server

# ตรวจสอบสถานะ
sudo systemctl status rabbitmq-server

# ตรวจสอบ logs
sudo journalctl -u rabbitmq-server -f
```

## 4. การตั้งค่าความปลอดภัย RabbitMQ

### 4.1 สร้าง Admin User

```bash
# สร้าง admin user
sudo rabbitmqctl add_user admin STRONG_PASSWORD_HERE

# ตั้งค่าเป็น administrator
sudo rabbitmqctl set_user_tags admin administrator

# ตั้งสิทธิ์ full access
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

### 4.2 ลบ Default Guest User (สำคัญ!)

```bash
# Guest user มีสิทธิ์เข้าถึงได้เฉพาะ localhost
# แต่เพื่อความปลอดภัย ควรลบหรือปิดการใช้งาน
sudo rabbitmqctl delete_user guest
```

### 4.3 สร้าง Application User

```bash
# สร้าง user สำหรับ application
sudo rabbitmqctl add_user appuser STRONG_PASSWORD_HERE

# ตั้งสิทธิ์เฉพาะ virtual host ที่ต้องการ
sudo rabbitmqctl set_permissions -p / appuser ".*" ".*" ".*"

# หรือจำกัดสิทธิ์เฉพาะ queue/exchange ที่ต้องการ
sudo rabbitmqctl set_permissions -p / appuser "^app-.*" "^app-.*" "^app-.*"
```

### 4.4 ตั้งค่า RabbitMQ Configuration

แก้ไขไฟล์ `/etc/rabbitmq/rabbitmq.conf`:

```bash
sudo nano /etc/rabbitmq/rabbitmq.conf
```

**การตั้งค่าความปลอดภัยที่สำคัญ**:

```conf
# 1. ตั้งค่า listeners
# สำหรับ localhost only (แนะนำ):
listeners.tcp.local = 127.0.0.1:5672

# สำหรับ network access (ระวัง!):
# listeners.tcp.default = 5672

# 2. ตั้งค่า management plugin
management.tcp.port = 15672
management.tcp.ip = 127.0.0.1  # หรือ IP ที่ต้องการ

# 3. ปิดการใช้งาน guest user
loopback_users.guest = false

# 4. ตั้งค่า default user และ password (ถ้ายังมี guest)
# default_user = admin
# default_pass = STRONG_PASSWORD

# 5. ตั้งค่า log level
log.console.level = info
log.file.level = info

# 6. ตั้งค่า memory limit
vm_memory_high_watermark.relative = 0.4  # 40% ของ RAM

# 7. ตั้งค่า disk free space limit
disk_free_limit.absolute = 2GB

# 8. ตั้งค่า heartbeat
heartbeat = 60

# 9. ตั้งค่า connection timeout
handshake_timeout = 10000

# 10. เปิดใช้งาน SSL/TLS (ถ้าต้องการ)
# listeners.ssl.default = 5671
# ssl_options.cacertfile = /etc/rabbitmq/ssl/ca_certificate.pem
# ssl_options.certfile = /etc/rabbitmq/ssl/server_certificate.pem
# ssl_options.keyfile = /etc/rabbitmq/ssl/server_key.pem
# ssl_options.verify = verify_peer
# ssl_options.fail_if_no_peer_cert = true
```

### 4.5 ตั้งค่า Environment Variables

แก้ไขไฟล์ `/etc/rabbitmq/rabbitmq-env.conf`:

```bash
sudo nano /etc/rabbitmq/rabbitmq-env.conf
```

```conf
# ตั้งค่า node name
NODENAME=rabbit@localhost

# ตั้งค่า config file path
CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf

# ตั้งค่า log file path
LOG_FILE=/var/log/rabbitmq/rabbitmq.log

# ตั้งค่า data directory
MNESIA_BASE=/var/lib/rabbitmq/mnesia
```

### 4.6 เปิดใช้งาน Management Plugin

```bash
# เปิดใช้งาน management plugin (Web UI)
sudo rabbitmq-plugins enable rabbitmq_management

# ตรวจสอบ plugins
sudo rabbitmq-plugins list
```

### 4.7 ตั้งค่า Firewall

```bash
# สำหรับ AMQP port (5672)
# sudo ufw allow from 192.168.1.0/24 to any port 5672

# สำหรับ Management UI (15672)
# sudo ufw allow from 192.168.1.0/24 to any port 15672

# สำหรับ localhost only (แนะนำ):
# ไม่ต้องเปิด port ใน firewall
```

## 5. การทดสอบการเชื่อมต่อ

### 5.1 ทดสอบด้วย rabbitmqctl

```bash
# ตรวจสอบสถานะ
sudo rabbitmqctl status

# ดู users
sudo rabbitmqctl list_users

# ดู virtual hosts
sudo rabbitmqctl list_vhosts

# ดู queues
sudo rabbitmqctl list_queues

# ดู exchanges
sudo rabbitmqctl list_exchanges

# ดู connections
sudo rabbitmqctl list_connections
```

### 5.2 ทดสอบด้วย Management UI

เข้าถึงผ่าน browser:
```
http://localhost:15672
```

Login ด้วย:
- Username: admin
- Password: STRONG_PASSWORD_HERE

### 5.3 ทดสอบด้วย Python (pika)

```python
import pika

# เชื่อมต่อ
credentials = pika.PlainCredentials('appuser', 'STRONG_PASSWORD_HERE')
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host='localhost',
        port=5672,
        credentials=credentials
    )
)

channel = connection.channel()

# สร้าง queue
channel.queue_declare(queue='test_queue')

# ส่ง message
channel.basic_publish(exchange='', routing_key='test_queue', body='Hello RabbitMQ!')

# รับ message
def callback(ch, method, properties, body):
    print(f"Received: {body}")

channel.basic_consume(queue='test_queue', on_message_callback=callback, auto_ack=True)
channel.start_consuming()

connection.close()
```

## 6. การตั้งค่าขั้นสูง

### 6.1 Virtual Hosts

```bash
# สร้าง virtual host
sudo rabbitmqctl add_vhost /app1

# ตั้งสิทธิ์ user ให้ virtual host
sudo rabbitmqctl set_permissions -p /app1 appuser ".*" ".*" ".*"

# ลบ virtual host
sudo rabbitmqctl delete_vhost /app1
```

### 6.2 SSL/TLS Configuration

**สร้าง SSL Certificates**:

```bash
# สร้าง directory
sudo mkdir -p /etc/rabbitmq/ssl
cd /etc/rabbitmq/ssl

# สร้าง CA key
sudo openssl genrsa -out ca_key.pem 2048

# สร้าง CA certificate
sudo openssl req -new -x509 -days 3650 -key ca_key.pem -out ca_certificate.pem

# สร้าง server key
sudo openssl genrsa -out server_key.pem 2048

# สร้าง server certificate request
sudo openssl req -new -key server_key.pem -out server_req.pem

# สร้าง server certificate
sudo openssl x509 -req -in server_req.pem -days 3650 -CA ca_certificate.pem -CAkey ca_key.pem -CAcreateserial -out server_certificate.pem

# ตั้งค่า permissions
sudo chown rabbitmq:rabbitmq /etc/rabbitmq/ssl/*
sudo chmod 600 /etc/rabbitmq/ssl/*
```

**ตั้งค่าใน rabbitmq.conf**:

```conf
listeners.ssl.default = 5671
ssl_options.cacertfile = /etc/rabbitmq/ssl/ca_certificate.pem
ssl_options.certfile = /etc/rabbitmq/ssl/server_certificate.pem
ssl_options.keyfile = /etc/rabbitmq/ssl/server_key.pem
ssl_options.verify = verify_peer
ssl_options.fail_if_no_peer_cert = false
```

### 6.3 Clustering (High Availability)

```bash
# บน node แรก (master)
sudo rabbitmqctl stop_app
sudo rabbitmqctl reset
sudo rabbitmqctl start_app

# บน node อื่นๆ (slave)
sudo rabbitmqctl stop_app
sudo rabbitmqctl reset
sudo rabbitmqctl join_cluster rabbit@master-node-hostname
sudo rabbitmqctl start_app

# ตรวจสอบ cluster status
sudo rabbitmqctl cluster_status
```

### 6.4 Memory และ Disk Management

```conf
# ใน rabbitmq.conf
# Memory limit (40% ของ RAM)
vm_memory_high_watermark.relative = 0.4

# หรือ absolute value
# vm_memory_high_watermark.absolute = 2GB

# Disk free space limit
disk_free_limit.absolute = 2GB

# หรือ relative
# disk_free_limit.relative = 1.0  # 100% ของ RAM
```

## 7. การจัดการและ Monitoring

### 7.1 คำสั่งที่มีประโยชน์

```bash
# ดูสถานะทั้งหมด
sudo rabbitmqctl status

# ดู users
sudo rabbitmqctl list_users

# ดู virtual hosts
sudo rabbitmqctl list_vhosts

# ดู queues
sudo rabbitmqctl list_queues name messages consumers

# ดู exchanges
sudo rabbitmqctl list_exchanges name type

# ดู bindings
sudo rabbitmqctl list_bindings

# ดู connections
sudo rabbitmqctl list_connections

# ดู channels
sudo rabbitmqctl list_channels

# ดู consumers
sudo rabbitmqctl list_consumers

# ดู node info
sudo rabbitmqctl environment
```

### 7.2 Monitoring ผ่าน Management UI

เข้าถึงผ่าน: `http://localhost:15672`

Features:
- Overview: สถานะโดยรวม
- Connections: การเชื่อมต่อทั้งหมด
- Channels: Channels ที่เปิดอยู่
- Exchanges: Exchanges ทั้งหมด
- Queues: Queues และ messages
- Admin: จัดการ users, virtual hosts, policies

### 7.3 Monitoring ผ่าน API

```bash
# ดู overview
curl -u admin:STRONG_PASSWORD http://localhost:15672/api/overview

# ดู queues
curl -u admin:STRONG_PASSWORD http://localhost:15672/api/queues

# ดู nodes
curl -u admin:STRONG_PASSWORD http://localhost:15672/api/nodes
```

### 7.4 Backup และ Restore

**Backup**:

```bash
# Backup definitions (users, vhosts, queues, exchanges, bindings)
sudo rabbitmqctl export_definitions /backup/rabbitmq-definitions-$(date +%Y%m%d).json

# Backup data directory
sudo systemctl stop rabbitmq-server
sudo tar -czf /backup/rabbitmq-data-$(date +%Y%m%d).tar.gz /var/lib/rabbitmq/mnesia
sudo systemctl start rabbitmq-server
```

**Restore**:

```bash
# Restore definitions
sudo rabbitmqctl import_definitions /backup/rabbitmq-definitions-YYYYMMDD.json

# Restore data (ระวัง!)
sudo systemctl stop rabbitmq-server
sudo rm -rf /var/lib/rabbitmq/mnesia/*
sudo tar -xzf /backup/rabbitmq-data-YYYYMMDD.tar.gz -C /
sudo systemctl start rabbitmq-server
```

## 8. Security Best Practices

### 8.1 Checklist ความปลอดภัย

- [x] ลบหรือปิดการใช้งาน guest user
- [x] สร้าง strong password สำหรับ admin user
- [x] จำกัด network access (bind ที่ IP ที่ต้องการ)
- [x] ตั้งค่า firewall rules
- [x] ใช้ SSL/TLS สำหรับ remote connections
- [x] จำกัด permissions ของ application users
- [x] ใช้ virtual hosts เพื่อแยกแอปพลิเคชัน
- [x] เปิดใช้งาน management plugin เฉพาะเมื่อจำเป็น
- [x] ตั้งค่า memory และ disk limits
- [x] ตรวจสอบ logs เป็นประจำ
- [x] อัปเดต RabbitMQ เป็นประจำ

### 8.2 User Management Best Practices

```bash
# สร้าง user พร้อม tags
sudo rabbitmqctl add_user appuser password
sudo rabbitmqctl set_user_tags appuser management  # สำหรับ management access

# ตั้งสิทธิ์แบบจำกัด
sudo rabbitmqctl set_permissions -p / appuser \
  "^app-.*" \      # configure permissions
  "^app-.*" \      # write permissions
  "^app-.*"        # read permissions
```

### 8.3 Policy Management

```bash
# สร้าง policy สำหรับ message TTL
sudo rabbitmqctl set_policy TTL ".*" '{"message-ttl":60000}' --apply-to queues

# สร้าง policy สำหรับ queue length limit
sudo rabbitmqctl set_policy max-length ".*" '{"max-length":1000}' --apply-to queues

# ดู policies
sudo rabbitmqctl list_policies

# ลบ policy
sudo rabbitmqctl clear_policy TTL
```

## 9. Troubleshooting

### 9.1 ปัญหาที่พบบ่อย

**RabbitMQ ไม่สามารถ start ได้**:
```bash
# ตรวจสอบ logs
sudo journalctl -u rabbitmq-server -n 50

# ตรวจสอบ Erlang version
erl -version

# ตรวจสอบ disk space
df -h
```

**Connection refused**:
```bash
# ตรวจสอบว่า RabbitMQ ทำงานอยู่
sudo systemctl status rabbitmq-server

# ตรวจสอบ port
sudo netstat -tlnp | grep 5672
```

**Memory issues**:
```bash
# ตรวจสอบ memory usage
sudo rabbitmqctl status | grep memory

# ตรวจสอบ memory limit
sudo rabbitmqctl environment | grep vm_memory
```

**Queue messages สะสม**:
```bash
# ดู queues ที่มี messages เยอะ
sudo rabbitmqctl list_queues name messages consumers

# Purge queue (ระวัง!)
sudo rabbitmqctl purge_queue queue_name
```

### 9.2 Performance Tuning

```conf
# ใน rabbitmq.conf
# เพิ่ม heartbeat timeout
heartbeat = 60

# เพิ่ม connection timeout
handshake_timeout = 10000

# ปรับ memory limit
vm_memory_high_watermark.relative = 0.4

# ปรับ disk free limit
disk_free_limit.absolute = 2GB

# เปิดใช้งาน lazy queues (สำหรับ queues ที่มี messages เยอะ)
# rabbitmqctl set_policy lazy "^lazy-.*" '{"queue-mode":"lazy"}' --apply-to queues
```

## 10. การถอนการติดตั้ง

```bash
# หยุดและปิดการใช้งาน service
sudo systemctl stop rabbitmq-server
sudo systemctl disable rabbitmq-server

# ลบ package
sudo apt remove --purge rabbitmq-server erlang-*

# ลบ config และ data (ระวัง!)
sudo rm -rf /etc/rabbitmq
sudo rm -rf /var/lib/rabbitmq
sudo rm -rf /var/log/rabbitmq

# ลบ repository
sudo rm /etc/apt/sources.list.d/rabbitmq.list
sudo rm /usr/share/keyrings/com.rabbitmq.team.gpg
```

## 11. หมายเหตุเพิ่มเติม

- RabbitMQ ใช้ Erlang/OTP - ตรวจสอบ compatibility ก่อนอัปเดต
- สำหรับ production, ควรใช้ RabbitMQ Cluster สำหรับ high availability
- Management UI ควรเข้าถึงได้เฉพาะจาก network ที่เชื่อถือได้
- ควรทำ backup definitions เป็นประจำ
- ตรวจสอบ RabbitMQ version: `sudo rabbitmqctl version`
- สำหรับ high throughput, พิจารณาใช้ lazy queues หรือ stream queues
- ควร monitor memory และ disk usage เป็นประจำ

