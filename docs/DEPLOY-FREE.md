# Deploy Miễn Phí lên Production — AI Wisdom Battle

## So sánh các lựa chọn

| Nền tảng | Loại | RAM | Phù hợp | Ghi chú |
|---|---|---|---|---|
| **Oracle Cloud Always Free** ⭐ | VM đầy đủ | 24 GB (ARM) | Full stack | Miễn phí mãi mãi |
| Fly.io + dịch vụ rời | PaaS | ~512 MB/app | Từng service | Cần ghép nhiều nền tảng |
| Render | PaaS | 512 MB | Frontend + API nhỏ | Ngủ sau 15 phút inactive |
| Railway | PaaS | ~512 MB | Dev/demo | $5 credit/tháng |

**Khuyến nghị: Oracle Cloud Always Free** — chạy toàn bộ `docker-compose.prod.yml` trên 1 VM, không cần tách service, không hết hạn.

---

## Phương án A — Oracle Cloud Always Free (Khuyến nghị)

### Tại sao Oracle Cloud?

- **4 OCPU + 24 GB RAM** ARM Ampere A1 — miễn phí mãi mãi (không phải trial 12 tháng)
- 200 GB Block Storage, 10 TB bandwidth/tháng
- Chạy toàn bộ Docker Compose: Spring Boot + Python + React + PostgreSQL + Neo4j + Redis

### A.1 Tạo tài khoản

1. Truy cập [oracle.com/cloud/free](https://www.oracle.com/cloud/free/)
2. Đăng ký — cần thẻ tín dụng để xác minh (không bị trừ tiền)
3. Chọn **Home Region** gần nhất (Singapore / Tokyo) — **không đổi được sau này**

### A.2 Tạo VM Always Free

Vào **Compute → Instances → Create Instance**:

```
Name:  awb-prod
Image: Canonical Ubuntu 22.04 (chọn "Change Image" → Ubuntu)
Shape: Ampere → VM.Standard.A1.Flex
  ├── OCPU: 4
  └── RAM:  24 GB
Boot volume: 100 GB
```

**SSH key**: Upload public key của bạn (hoặc để Oracle tạo, tải về `.pem`).

### A.3 Mở port trong Security List

Vào **Networking → Virtual Cloud Networks → [VCN của bạn] → Security Lists → Default**:

Thêm Ingress Rules:

| Protocol | Source CIDR | Port | Mục đích |
|---|---|---|---|
| TCP | 0.0.0.0/0 | 22 | SSH |
| TCP | 0.0.0.0/0 | 80 | HTTP (frontend) |
| TCP | 0.0.0.0/0 | 443 | HTTPS (nếu cần) |
| TCP | 0.0.0.0/0 | 8080 | API (tạm thời, bỏ sau khi có nginx) |

Ngoài Security List, còn phải mở firewall của VM:

```bash
# Trên VM sau khi SSH vào
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### A.4 SSH vào VM

```bash
ssh -i ~/.ssh/<your-key>.pem ubuntu@<PUBLIC_IP>
```

### A.5 Cài Docker

```bash
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
newgrp docker

# Kiểm tra
docker compose version
```

### A.6 Clone và cấu hình

```bash
sudo mkdir -p /opt/ai-wisdom-battle
sudo chown $USER:$USER /opt/ai-wisdom-battle

git clone <repo-url> /opt/ai-wisdom-battle
cd /opt/ai-wisdom-battle

cp .env.example .env
nano .env
```

Điền `.env` (xem bảng bên dưới):

```dotenv
POSTGRES_DB=ai_wisdom_battle
POSTGRES_USER=awb_user
POSTGRES_PASSWORD=$(openssl rand -base64 24)

NEO4J_USER=neo4j
NEO4J_PASSWORD=$(openssl rand -base64 24)

REDIS_PASSWORD=$(openssl rand -base64 24)

JWT_SECRET=$(openssl rand -base64 48)
JWT_EXPIRATION_MS=86400000

INTERNAL_API_KEY=$(openssl rand -base64 32)

# Domain công khai của bạn (hoặc IP nếu chưa có domain)
CORS_ALLOWED_ORIGINS=http://<PUBLIC_IP>
# Nếu có domain: CORS_ALLOWED_ORIGINS=https://yourdomain.com

APP_VERSION=1.0.0
RATE_LIMIT_AUTH_MAX=20
FRONTEND_PORT=80
FRONTEND_HTTPS_PORT=443
```

> **Mẹo tạo password nhanh:**
> ```bash
> openssl rand -base64 32
> ```

```bash
chmod 600 .env
```

### A.7 Build và khởi động

```bash
cd /opt/ai-wisdom-battle

# Build tất cả images (~5-10 phút lần đầu)
docker compose -f docker-compose.prod.yml build

# Khởi động
docker compose -f docker-compose.prod.yml up -d

# Theo dõi
docker compose -f docker-compose.prod.yml logs -f
```

### A.8 Kiểm tra

```bash
# Chờ ~60s rồi chạy
docker compose -f docker-compose.prod.yml ps

# Backend
curl http://<PUBLIC_IP>:8080/actuator/health

# Frontend
curl -I http://<PUBLIC_IP>:80
```

### A.9 Tự khởi động khi reboot VM

```bash
# Tạo systemd service
sudo tee /etc/systemd/system/awb.service <<'EOF'
[Unit]
Description=AI Wisdom Battle
Requires=docker.service
After=docker.service network-online.target

[Service]
WorkingDirectory=/opt/ai-wisdom-battle
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml up
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml down
Restart=on-failure
RestartSec=10
User=ubuntu

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable awb
```

---

## Phương án B — Ghép các dịch vụ miễn phí (không cần server)

Phù hợp nếu không muốn quản lý VM. Cần ghép 5 dịch vụ:

| Thành phần | Dịch vụ | Free tier |
|---|---|---|
| PostgreSQL | [Aiven](https://aiven.io) | 1 DB, 5 GB |
| Neo4j | [Neo4j Aura Free](https://neo4j.com/cloud/aura-free/) | 1 instance, 200K nodes |
| Redis | [Redis Cloud](https://redis.io/try-free/) | 30 MB |
| Spring Boot + Python | [Fly.io](https://fly.io) | 3 shared VMs 256MB |
| React Frontend | [Cloudflare Pages](https://pages.cloudflare.com) | Không giới hạn |

> **Nhược điểm Phương án B**: Neo4j Aura Free chỉ 200K nodes, Redis Cloud 30MB chỉ vừa đủ cho rate limiting, Fly.io 256MB/VM vừa sát giới hạn Spring Boot.

### B.1 PostgreSQL — Aiven

1. [app.aiven.io](https://app.aiven.io) → Create Service → PostgreSQL → Free plan
2. Lấy connection string dạng: `postgres://user:pass@host:port/db?sslmode=require`
3. Đặt vào biến `DB_URL` khi deploy Fly.io

### B.2 Neo4j — Aura Free

1. [console.neo4j.io](https://console.neo4j.io) → Create Free Instance
2. Lưu password ngay (chỉ hiện 1 lần)
3. Bolt URI dạng: `neo4j+s://xxxxxxxx.databases.neo4j.io`

### B.3 Redis — Redis Cloud

1. [redis.io/try-free](https://redis.io/try-free/) → Create free database
2. Lấy: host, port, password
3. Đặt vào `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`

### B.4 Spring Boot — Fly.io

```bash
# Cài flyctl
curl -L https://fly.io/install.sh | sh
fly auth signup   # hoặc fly auth login

cd /path/to/ai-wisdom-battle

# Khởi tạo app (chọn region gần nhất)
fly launch --no-deploy --name awb-backend

# Đặt secrets (biến môi trường)
fly secrets set \
  DB_URL="jdbc:postgresql://host:port/db?sslmode=require" \
  DB_USER="avnadmin" \
  DB_PASSWORD="..." \
  NEO4J_URI="neo4j+s://xxx.databases.neo4j.io" \
  NEO4J_USER="neo4j" \
  NEO4J_PASSWORD="..." \
  REDIS_HOST="redis-host.cloud.redislabs.com" \
  REDIS_PORT="12345" \
  REDIS_PASSWORD="..." \
  JWT_SECRET="$(openssl rand -base64 48)" \
  INTERNAL_API_KEY="$(openssl rand -base64 32)" \
  CORS_ALLOWED_ORIGINS="https://your-app.pages.dev"

# Deploy
fly deploy
```

`fly.toml` sẽ được tạo tự động. Thêm:

```toml
[build]
  dockerfile = "Dockerfile"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
  [[services.ports]]
    port = 80
    handlers = ["http"]
```

### B.5 Python Engine — Fly.io

```bash
cd adaptive-engine

fly launch --no-deploy --name awb-engine
fly secrets set \
  JAVA_SERVICE_URL="https://awb-backend.fly.dev" \
  INTERNAL_API_KEY="..."
fly deploy
```

### B.6 React Frontend — Cloudflare Pages

```bash
# Cài wrangler
npm install -g wrangler
wrangler login

cd frontend
npm run build

# Deploy
wrangler pages deploy dist \
  --project-name ai-wisdom-battle \
  --branch main
```

Hoặc kết nối GitHub repo trực tiếp tại [pages.cloudflare.com](https://pages.cloudflare.com):

- Build command: `npm run build`
- Build output: `dist`
- Environment variable: `VITE_API_BASE_URL=https://awb-backend.fly.dev/api/v1`

---

## Thêm domain và HTTPS (tùy chọn)

### Nếu dùng Oracle Cloud (Phương án A)

Dùng **Cloudflare** làm reverse proxy miễn phí:

1. Đăng ký [cloudflare.com](https://cloudflare.com), thêm domain
2. Trỏ DNS A record `@` và `www` → IP Oracle VM
3. Bật **Proxy** (cam Cloudflare) → tự động HTTPS

Không cần cài certbot hay nginx riêng — Cloudflare xử lý SSL.

### Nếu không có domain, dùng IP trực tiếp

```bash
# Truy cập thẳng qua IP
http://<PUBLIC_IP>       # frontend
http://<PUBLIC_IP>:8080  # API
```

---

## Checklist trước khi go-live

- [ ] `.env` không còn giá trị `change_me_*`
- [ ] `JWT_SECRET` ít nhất 32 ký tự ngẫu nhiên
- [ ] Tất cả containers `healthy` (`docker compose ps`)
- [ ] `curl /actuator/health` trả về `{"status":"UP"}`
- [ ] Frontend load được ở trình duyệt
- [ ] Đăng ký và đăng nhập thử nghiệm thành công
- [ ] Rate limit trả 429 khi gửi >20 request/phút
- [ ] Systemd service đã được `enable` (Phương án A)
