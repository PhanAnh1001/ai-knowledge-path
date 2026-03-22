# Hướng dẫn Deploy — AI Wisdom Battle

## Chọn phương án deploy

| Phương án | Mô tả | Phù hợp |
|---|---|---|
| **[DEPLOY-ORACLE.md](./DEPLOY-ORACLE.md)** | Oracle Cloud Always Free — **setup thủ công** qua web console | Người mới, muốn hiểu từng bước |
| **[DEPLOY-TERRAFORM.md](./DEPLOY-TERRAFORM.md)** | Oracle Cloud Always Free — **Terraform (IaC)**, 1 lệnh tạo toàn bộ hạ tầng | DevOps, muốn tự động hóa |
| **Tài liệu này** | Docker Compose trên bất kỳ Linux server nào | Đã có VPS/server riêng |

> **Khuyến nghị cho lần đầu**: đọc `DEPLOY-ORACLE.md` (thủ công) để hiểu kiến trúc,
> sau đó dùng `DEPLOY-TERRAFORM.md` cho các môi trường tiếp theo.

---

## Mục lục (Docker Compose trên server có sẵn)

1. [Yêu cầu môi trường](#1-yêu-cầu-môi-trường)
2. [Chuẩn bị server](#2-chuẩn-bị-server)
3. [Cấu hình biến môi trường](#3-cấu-hình-biến-môi-trường)
4. [Build và Deploy](#4-build-và-deploy)
5. [Kiểm tra sau deploy](#5-kiểm-tra-sau-deploy)
6. [Rollback](#6-rollback)
7. [Cập nhật (Rolling Update)](#7-cập-nhật-rolling-update)
8. [Xử lý sự cố thường gặp](#8-xử-lý-sự-cố-thường-gặp)

---

## 1. Yêu cầu môi trường

| Thành phần | Phiên bản tối thiểu | Ghi chú |
|---|---|---|
| Docker Engine | 24+ | `docker --version` |
| Docker Compose | v2.20+ (plugin) | `docker compose version` |
| RAM server | 4 GB | 6–8 GB khuyến nghị |
| Disk | 20 GB | cho data volumes |
| OS | Ubuntu 22.04+ / Debian 12+ | hoặc bất kỳ Linux đủ mới |

---

## 2. Chuẩn bị server

```bash
# Cài Docker (Ubuntu)
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
newgrp docker

# Kiểm tra
docker compose version
# Docker Compose version v2.x.x
```

Clone code về server:

```bash
git clone <repo-url> /opt/ai-wisdom-battle
cd /opt/ai-wisdom-battle
```

---

## 3. Cấu hình biến môi trường

```bash
cp .env.example .env
nano .env          # hoặc vim .env
```

**Các giá trị BẮT BUỘC phải đổi** (không để mặc định):

```dotenv
# Tạo JWT secret ngẫu nhiên:
#   openssl rand -base64 48
JWT_SECRET=<chuỗi ngẫu nhiên tối thiểu 32 ký tự>

# Đổi tất cả password
POSTGRES_PASSWORD=<mật_khẩu_mạnh>
NEO4J_PASSWORD=<mật_khẩu_mạnh>
REDIS_PASSWORD=<mật_khẩu_mạnh>
INTERNAL_API_KEY=<chuỗi ngẫu nhiên>

# Domain frontend thật (không phải localhost)
CORS_ALLOWED_ORIGINS=https://yourdomain.com

# Tên/version DB
POSTGRES_DB=ai_wisdom_battle
POSTGRES_USER=awb_user
NEO4J_USER=neo4j
APP_VERSION=1.0.0
```

Bảo vệ file `.env`:

```bash
chmod 600 .env
```

---

## 4. Build và Deploy

### 4.1 Build images lần đầu

```bash
# Build tất cả images (Spring Boot + Python Engine + React Frontend)
docker compose -f docker-compose.prod.yml build --no-cache

# Kiểm tra images vừa build
docker images | grep awb-
```

Ví dụ output:
```
awb-app              1.0.0   abc123   ...
awb-adaptive-engine  1.0.0   def456   ...
awb-frontend         1.0.0   ghi789   ...
```

### 4.2 Khởi động

```bash
# Khởi động tất cả services
docker compose -f docker-compose.prod.yml up -d

# Theo dõi log trong 60s đầu
docker compose -f docker-compose.prod.yml logs -f --since=0s
```

### 4.3 Seed Neo4j (chỉ lần đầu)

Seeder container tự động chạy và thoát sau khi seed xong. Kiểm tra:

```bash
docker logs awb-neo4j-seeder
# Expected: "Seed complete."
```

---

## 5. Kiểm tra sau deploy

### Health checks tự động

```bash
# Trạng thái tất cả containers (chờ ~60s sau khi up)
docker compose -f docker-compose.prod.yml ps
```

Mong đợi cột `STATUS` là `healthy` cho mọi service:
```
NAME                  STATUS
awb-postgres          healthy
awb-neo4j             healthy
awb-redis             healthy
awb-app               healthy
awb-adaptive-engine   healthy
awb-frontend          healthy
```

### Kiểm tra thủ công

```bash
# Backend health
curl -s http://localhost:8080/actuator/health
# {"status":"UP"}

# Backend API (đăng ký user thử)
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","displayName":"Tester","password":"Test1234!","explorerType":"nature","ageGroup":"adult_18_plus"}' \
  | python3 -m json.tool

# Python Adaptive Engine health
curl -s http://localhost:8001/health
# {"status":"ok"}

# Frontend (qua nginx)
curl -s -o /dev/null -w "%{http_code}" http://localhost:80
# 200
```

### Rate limit hoạt động

```bash
# Gửi 25 request liên tục, phải thấy 429 sau request thứ 20
for i in $(seq 1 25); do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST http://localhost:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"x@x.com","password":"wrong"}')
  echo "Request $i: HTTP $code"
done
```

---

## 6. Rollback

Nếu deploy mới bị lỗi, rollback về version cũ:

```bash
# Đặt lại APP_VERSION về version cũ trong .env
APP_VERSION=0.9.0   # ví dụ

# Khởi động lại chỉ services bị ảnh hưởng
docker compose -f docker-compose.prod.yml up -d --no-deps app adaptive-engine frontend
```

Hoặc rollback toàn bộ:

```bash
docker compose -f docker-compose.prod.yml down
APP_VERSION=0.9.0 docker compose -f docker-compose.prod.yml up -d
```

---

## 7. Cập nhật (Rolling Update)

Khi có code mới:

```bash
# 1. Pull code mới
git pull origin main

# 2. Tăng version
nano .env   # APP_VERSION=1.1.0

# 3. Rebuild chỉ image thay đổi (ví dụ chỉ backend)
docker compose -f docker-compose.prod.yml build app

# 4. Khởi động lại service đó (DB/Redis không restart)
docker compose -f docker-compose.prod.yml up -d --no-deps app

# 5. Kiểm tra health
docker compose -f docker-compose.prod.yml ps
```

---

## 8. Xử lý sự cố thường gặp

### App không start — "Connection refused" tới DB

```bash
docker compose -f docker-compose.prod.yml logs postgres | tail -20
docker compose -f docker-compose.prod.yml logs app | grep -i "error\|fatal\|refused"
```

Nguyên nhân thường gặp: **app start trước khi postgres healthy** → tự resolve nhờ `depends_on: condition: service_healthy`.
Nếu vẫn lỗi sau 2 phút, kiểm tra biến `POSTGRES_PASSWORD` trong `.env` có khớp không.

---

### Neo4j không healthy

```bash
docker compose -f docker-compose.prod.yml logs neo4j | tail -30
```

Neo4j cần ~30s để khởi động. Nếu vẫn `unhealthy` sau 2 phút:

```bash
# Kiểm tra RAM — Neo4j cần ít nhất 1.5 GB
free -h

# Giảm memory nếu server ít RAM
docker compose -f docker-compose.prod.yml exec neo4j \
  cypher-shell -u neo4j -p $NEO4J_PASSWORD "RETURN 1"
```

---

### 429 Too Many Requests ngay từ đầu

Rate limit đang bị trigger từ IP `::1` (localhost khi test). Đây là hành vi đúng.
Nếu bị ảnh hưởng production, tăng giới hạn trong `.env`:

```dotenv
RATE_LIMIT_AUTH_MAX=50
```

Rồi restart app:

```bash
docker compose -f docker-compose.prod.yml up -d --no-deps app
```

---

### Xem logs

```bash
# Tất cả services
docker compose -f docker-compose.prod.yml logs -f

# Chỉ một service
docker compose -f docker-compose.prod.yml logs -f app
docker compose -f docker-compose.prod.yml logs -f adaptive-engine

# Log N dòng cuối
docker compose -f docker-compose.prod.yml logs --tail=100 app
```

---

### Dừng toàn bộ (không xóa data)

```bash
docker compose -f docker-compose.prod.yml down
```

### Dừng và XÓA data (cẩn thận!)

```bash
docker compose -f docker-compose.prod.yml down -v
```
