# Day 5 — Lightsail Deploy + Data Migration

> **Mục tiêu:** Production live trên AWS Lightsail Singapore, frontend kết nối Go backend, data Neo4j đã được migrate sang PostgreSQL.
>
> **Thời gian ước tính:** 2–3 tiếng (lần đầu)
>
> **Prerequisite:** Day 1–4 đã hoàn thành — branch `claude/lightsail-migration-gBk3t` đã pass CI.

---

## Mục lục

1. [Prerequisites](#0-prerequisites)
2. [Provision AWS Lightsail Instance (Terraform)](#1-provision-aws-lightsail-instance-terraform)
3. [Bootstrap instance (lightsail-init.sh)](#2-bootstrap-instance)
4. [Cấu hình Cloudflare](#3-cấu-hình-cloudflare)
5. [Cấu hình GitHub Secrets](#4-cấu-hình-github-secrets)
6. [Build & Push Docker image lần đầu](#5-build--push-docker-image-lần-đầu)
7. [Migrate data Neo4j → PostgreSQL](#6-migrate-data-neo4j--postgresql)
8. [Deploy lần đầu lên Lightsail](#7-deploy-lần-đầu-lên-lightsail)
9. [Smoke Test API](#8-smoke-test-api)
10. [Smoke Test Frontend](#9-smoke-test-frontend)
11. [Rollback](#10-rollback)
12. [Checklist cuối ngày](#11-checklist-cuối-ngày)

---

## 0. Prerequisites

### Công cụ cần có trên máy local

```bash
# Kiểm tra
gh --version            # GitHub CLI (optional, dùng tạo secrets)
ssh -V                  # OpenSSH
python3 --version       # >= 3.10  (cho migration script)
docker --version        # (optional, để build image thủ công)
```

Cài nếu thiếu:
```bash
# macOS
brew install gh

# Ubuntu / Debian
sudo apt install gh
```

> **Không cần AWS CLI.** Lightsail instance được tạo hoàn toàn qua Terraform chạy trên GitHub Actions — không cần cài `aws` trên máy local.

### Tài khoản cần có

| Tài khoản | Mục đích |
|---|---|
| AWS (có thẻ tín dụng) | Tạo Lightsail instance (qua Terraform) |
| Cloudflare (free) | DNS + proxy |
| GitHub | Secrets + Container Registry (GHCR) + chạy Terraform |

---

## 1. Provision AWS Lightsail Instance (Terraform)

> Thay vì dùng AWS CLI thủ công, instance được tạo qua **Terraform chạy trên GitHub Actions**.
> Terraform code nằm tại `infra/lightsail/`, workflow tại `.github/workflows/terraform-lightsail.yml`.

### 1.1 Tạo SSH key pair (máy local)

```bash
# Tạo key pair (ed25519 — nhẹ và an toàn)
ssh-keygen -t ed25519 -C "awb-lightsail-deploy" -f ~/.ssh/awb-lightsail

# Kết quả:
#   ~/.ssh/awb-lightsail      ← private key (KHÔNG share, lưu an toàn)
#   ~/.ssh/awb-lightsail.pub  ← public key  (sẽ upload qua GitHub Secret)
```

### 1.2 Lấy AWS Access Key

1. Đăng nhập [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. **Users** → chọn user của bạn → **Security credentials**
3. **Access keys** → **Create access key** → chọn use case **CLI**
4. Lưu lại `Access key ID` và `Secret access key` — chỉ hiển thị **một lần**!

> Nếu chưa có IAM user: **IAM** → **Users** → **Create user** → gán policy `AmazonLightsailFullAccess`.

### 1.3 Thêm Secrets vào GitHub

**Repo Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret name | Giá trị | Cách lấy |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Access key ID | IAM → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Secret access key | Cùng lúc tạo Access key |
| `SSH_PUBLIC_KEY` | Nội dung `~/.ssh/awb-lightsail.pub` | `cat ~/.ssh/awb-lightsail.pub` |

Hoặc dùng GitHub CLI:
```bash
gh auth login

gh secret set AWS_ACCESS_KEY_ID      --body "<access-key-id>"
gh secret set AWS_SECRET_ACCESS_KEY  --body "<secret-access-key>"
gh secret set SSH_PUBLIC_KEY         < ~/.ssh/awb-lightsail.pub
```

> `SSH_PUBLIC_KEY` đã dùng cho Oracle Cloud — nếu dùng cùng SSH key thì không cần tạo lại.

### 1.4 Chạy Terraform Apply trên GitHub Actions

1. Truy cập **GitHub repo** → tab **Actions**
2. Chọn workflow **"Terraform (AWS Lightsail)"**
3. Nhấn **"Run workflow"** → chọn branch `claude/lightsail-migration-gBk3t` → **action: `apply`** → **Run workflow**
4. Chờ workflow hoàn thành (~3 phút)

**Xem kết quả:**

Trong log của step **"Terraform Output"**, bạn sẽ thấy:
```
ipv6_address = "2406:da18:886:3400:abcd:1234:5678:ef90"
instance_name = "awb-prod"
ssh_command = "ssh -i ~/.ssh/awb-lightsail ubuntu@2406:da18:886:3400:abcd:1234:5678:ef90"
```

> **Lưu lại IPv6 address** — dùng ở bước 3 (Cloudflare AAAA record) và bước 4 (GitHub Secret `LIGHTSAIL_HOST`).

**Terraform đã tự động:**
- Upload SSH public key → `awb-deploy-key`
- Tạo instance Ubuntu 22.04 · `nano_3_0` · 2vCPU · 2GB · $7/tháng · IPv6-only
- Chạy `lightsail-init.sh` khi boot (cài Docker, clone repo, cấu hình firewall)
- Mở firewall ports: TCP 22/80/443 và UDP 443

### 1.5 SSH vào instance lần đầu

```bash
# Thay <IPv6> bằng địa chỉ lấy từ Terraform output
ssh -i ~/.ssh/awb-lightsail ubuntu@<IPv6>

# Nếu máy local không có IPv6, dùng Lightsail browser SSH:
#   AWS Console → Lightsail → awb-prod → Connect using SSH
```

---

## 2. Bootstrap Instance

> `lightsail-init.sh` đã được chạy tự động qua `--user-data`. Kiểm tra trạng thái:

```bash
# SSH vào instance
ssh -i ~/.ssh/awb-lightsail ubuntu@<IPv6>

# Kiểm tra cloud-init đã hoàn thành
sudo cloud-init status
# → status: done

# Kiểm tra Docker đang chạy
sudo systemctl status docker
docker --version

# Kiểm tra repo đã clone
ls /opt/ai-wisdom-battle/

# Kiểm tra .env placeholder đã tạo
cat /opt/ai-wisdom-battle/.env
```

### 2.1 Điền .env production

```bash
# Trên instance
cd /opt/ai-wisdom-battle

# Tạo JWT secret
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET: $JWT_SECRET"  # Lưu lại!

# Sửa .env
nano .env
```

Nội dung `.env` trên Lightsail:

```env
# PostgreSQL
POSTGRES_DB=ai_wisdom_battle
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<strong-password>

# Go Backend
PORT=8080
DATABASE_URL=postgres://postgres:<strong-password>@postgres:5432/ai_wisdom_battle

# JWT
JWT_SECRET=<giá trị từ openssl rand>
JWT_EXPIRATION_MS=86400000
JWT_REFRESH_EXPIRATION_MS=2592000000

# CORS
CORS_ALLOWED_ORIGINS=https://aiwisdombattle.com,https://www.aiwisdombattle.com

# Rate Limiting
RATE_LIMIT_MAX=20
RATE_LIMIT_WINDOW=60

# Cloudflare (cho Caddy DNS-01)
CLOUDFLARE_API_TOKEN=<lấy ở bước 3>

# Docker image
IMAGE_TAG=latest
```

---

## 3. Cấu hình Cloudflare

### 3.1 Thêm AAAA record

1. Đăng nhập [dash.cloudflare.com](https://dash.cloudflare.com)
2. Chọn domain `aiwisdombattle.com`
3. **DNS** → **Add record**:

| Field | Value |
|---|---|
| Type | `AAAA` |
| Name | `api` |
| IPv6 address | `2406:da18:886:3400:abcd:1234:5678:ef90` (IPv6 từ bước 1.4) |
| Proxy status | **Proxied** (cloud cam) |
| TTL | Auto |

> **Tại sao Proxied?** Cloudflare làm bridge IPv4↔IPv6. User dùng IPv4 vẫn kết nối được vì Cloudflare nhận IPv4 rồi forward sang IPv6 Lightsail.

### 3.2 Cấu hình SSL

**SSL/TLS** → **Overview** → chọn **Full (strict)**

> - `Full (strict)`: Cloudflare ↔ Origin phải có cert hợp lệ
> - Caddy tự lấy cert qua Cloudflare DNS-01 challenge → thỏa mãn yêu cầu này

### 3.3 Tạo Cloudflare API Token cho Caddy

1. **My Profile** (avatar góc trên phải) → **API Tokens**
2. **Create Token** → **Edit zone DNS** template
3. Cấu hình:

| Field | Value |
|---|---|
| Token name | `awb-caddy-dns-challenge` |
| Permissions | Zone · DNS · Edit |
| Zone Resources | Include · Specific zone · `aiwisdombattle.com` |
| TTL | No expiry (hoặc 1 năm) |

4. **Continue to summary** → **Create Token**
5. Lưu token — chỉ hiển thị **một lần**!

Điền token vào `.env` trên Lightsail (`CLOUDFLARE_API_TOKEN=...`).

### 3.4 Cấu hình trang Cloudflare Pages (frontend)

1. **Workers & Pages** → **Create application** → **Pages**
2. **Connect to Git** → chọn repo `ai-wisdom-battle`
3. Cấu hình build:

| Field | Value |
|---|---|
| Project name | `ai-wisdom-battle` |
| Production branch | `master` |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Root directory | `frontend` |

4. **Environment variables** (Production):

| Variable | Value |
|---|---|
| `VITE_API_BASE_URL` | `https://api.aiwisdombattle.com/api/v1` |

5. **Save and Deploy**

Sau khi deploy xong, Cloudflare Pages sẽ cấp subdomain dạng `ai-wisdom-battle.pages.dev`. Bạn có thể thêm custom domain `aiwisdombattle.com` sau.

---

## 4. Cấu hình GitHub Secrets

### 4.1 Secrets cần tạo

Truy cập: **GitHub repo** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret name | Giá trị | Cách lấy | Dùng cho |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | Access key ID | IAM → Security credentials | Terraform Lightsail |
| `AWS_SECRET_ACCESS_KEY` | Secret access key | Cùng lúc tạo Access key | Terraform Lightsail |
| `SSH_PUBLIC_KEY` | Nội dung `~/.ssh/awb-lightsail.pub` | `cat ~/.ssh/awb-lightsail.pub` | Terraform (upload key) |
| `LIGHTSAIL_HOST` | IPv6 từ Terraform output | Bước 1.4 — workflow log | Deploy workflow |
| `LIGHTSAIL_SSH_KEY` | Nội dung `~/.ssh/awb-lightsail` | `cat ~/.ssh/awb-lightsail` | Deploy workflow (SSH) |
| `CLOUDFLARE_API_TOKEN` | Token từ bước 3.3 | Cloudflare dashboard | Deploy frontend + Caddy |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID | Cloudflare → sidebar phải | Deploy frontend |

> **Thứ tự quan trọng:** Tạo `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `SSH_PUBLIC_KEY` **trước** khi chạy Terraform (bước 1.3). Tạo `LIGHTSAIL_HOST` **sau** khi có IPv6 từ Terraform output (bước 1.4).

### 4.2 Variables cần tạo

**Settings** → **Secrets and variables** → **Actions** → **Variables** → **New repository variable**

| Variable name | Giá trị |
|---|---|
| `VITE_API_BASE_URL` | `https://api.aiwisdombattle.com/api/v1` |

### 4.3 Dùng GitHub CLI (nhanh hơn)

```bash
# Login GitHub CLI
gh auth login

# Secrets cho Terraform Lightsail (tạo trước bước 1.3)
gh secret set AWS_ACCESS_KEY_ID      --body "<access-key-id>"
gh secret set AWS_SECRET_ACCESS_KEY  --body "<secret-access-key>"
gh secret set SSH_PUBLIC_KEY         < ~/.ssh/awb-lightsail.pub

# Secrets cho Deploy workflow (tạo sau bước 1.4 khi có IPv6)
gh secret set LIGHTSAIL_HOST         --body "<IPv6-từ-terraform-output>"
gh secret set LIGHTSAIL_SSH_KEY      < ~/.ssh/awb-lightsail
gh secret set CLOUDFLARE_API_TOKEN   --body "<token>"
gh secret set CLOUDFLARE_ACCOUNT_ID  --body "<account_id>"

# Variable
gh variable set VITE_API_BASE_URL --body "https://api.aiwisdombattle.com/api/v1"
```

### 4.4 Cấp quyền GHCR cho Actions

GitHub Container Registry (ghcr.io) dùng để lưu Docker image.

**Repo Settings** → **Actions** → **General** → **Workflow permissions** → chọn **Read and write permissions** → Save.

---

## 5. Build & Push Docker Image lần đầu

> CI pipeline sẽ tự build và push sau. Bước này là cho lần deploy đầu tiên thủ công.

```bash
# Trên máy local, tại thư mục gốc repo
cd /path/to/ai-wisdom-battle

# Login GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u <github-username> --password-stdin

# Build image
docker build -t ghcr.io/aiwisdombattle/backend-go:latest ./backend-go

# Push
docker push ghcr.io/aiwisdombattle/backend-go:latest
```

> Hoặc trigger CI bằng cách push commit nhỏ lên branch và merge vào master.

---

## 6. Migrate Data Neo4j → PostgreSQL

> **Thực hiện trên máy có thể reach cả Neo4j (Oracle VM cũ) và internet.**

### 6.1 Cài dependencies

```bash
pip install neo4j psycopg2-binary python-dotenv
```

### 6.2 Tạo .env cho migration script

```bash
# Tạo file .env.migrate (không commit)
cat > .env.migrate << 'EOF'
NEO4J_URI=bolt://<oracle-vm-ip>:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=<neo4j-password>
DATABASE_URL=postgres://postgres:<password>@<lightsail-ipv6>:5432/ai_wisdom_battle
EOF
```

> **Lưu ý:** PostgreSQL trên Lightsail **không expose port 5432 ra ngoài** (chỉ accessible từ Docker internal network). Cần dùng SSH tunnel:

```bash
# Mở SSH tunnel: port 5433 local → port 5432 trên Lightsail (qua Docker)
ssh -i ~/.ssh/awb-lightsail \
  -L 5433:localhost:5432 \
  -N ubuntu@<IPv6> &

# Sau đó dùng DATABASE_URL qua tunnel
DATABASE_URL=postgres://postgres:<password>@localhost:5433/ai_wisdom_battle
```

### 6.3 Chạy export trước (dry run)

```bash
# Export CSV từ Neo4j, chưa import vào PostgreSQL
python3 scripts/migrate-neo4j-to-pg.py \
  --dry-run \
  --csv-dir ./migration-export

# Kiểm tra output
head -5 migration-export/knowledge_nodes.csv
head -5 migration-export/node_relations.csv
wc -l migration-export/*.csv
```

**Kết quả mong đợi:**
```
knowledge_nodes.csv: N nodes exported
node_relations.csv:  M relationships exported
```

Xem qua CSV để kiểm tra dữ liệu có đúng không trước khi import.

### 6.4 Import vào PostgreSQL

```bash
# Đảm bảo SSH tunnel đang mở (bước 6.2)
# Đảm bảo Go backend đã chạy ít nhất một lần (để migration SQL đã được apply)

python3 scripts/migrate-neo4j-to-pg.py \
  --import-only \
  --csv-dir ./migration-export

# Expected output:
#   knowledge_nodes: X inserted, Y updated
#   node_relations: Z inserted, 0 skipped
#   Migration complete!
```

### 6.5 Xác nhận dữ liệu

```bash
# Kết nối qua tunnel
psql "postgres://postgres:<password>@localhost:5433/ai_wisdom_battle"
```

```sql
-- Kiểm tra số lượng
SELECT COUNT(*) FROM knowledge_nodes WHERE is_published = TRUE;
SELECT COUNT(*), relation_type FROM node_relations GROUP BY relation_type;

-- Kiểm tra một node mẫu
SELECT id, title, domain, difficulty, is_published
FROM knowledge_nodes
LIMIT 5;

-- Kiểm tra relations
SELECT
    n1.title AS from_node,
    nr.relation_type,
    n2.title AS to_node,
    nr.weight
FROM node_relations nr
JOIN knowledge_nodes n1 ON n1.id = nr.from_node_id
JOIN knowledge_nodes n2 ON n2.id = nr.to_node_id
WHERE nr.relation_type = 'LEADS_TO'
LIMIT 10;
```

---

## 7. Deploy lần đầu lên Lightsail

### 7.1 SSH vào instance

```bash
ssh -i ~/.ssh/awb-lightsail ubuntu@<IPv6>
cd /opt/ai-wisdom-battle
```

### 7.2 Pull code mới nhất

```bash
git fetch origin master
git reset --hard origin/master
```

### 7.3 Pull Docker image

```bash
# Login GHCR từ instance
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin

# Hoặc dùng token không cần password (read-only public image)
docker pull ghcr.io/aiwisdombattle/backend-go:latest
```

### 7.4 Khởi động stack

```bash
# Lần đầu: start tất cả containers
docker compose -f docker-compose.prod.yml up -d

# Xem logs
docker compose -f docker-compose.prod.yml logs -f
```

**Output mong đợi:**
```
awb-postgres  | LOG:  database system is ready to accept connections
awb-app       | database migrations applied
awb-app       | server listening on :8080
awb-caddy     | {"level":"info","ts":...,"msg":"serving initial configuration"}
```

### 7.5 Kiểm tra health check local

```bash
# Trên instance
curl -s http://localhost:8080/health
# → {"status":"UP"}

# Qua Caddy (HTTPS)
curl -s https://api.aiwisdombattle.com/health
# → {"status":"UP"}
```

---

## 8. Smoke Test API

Chạy từ máy local (thay `<token>` sau khi register/login):

### 8.1 Register

```bash
curl -s -X POST https://api.aiwisdombattle.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "displayName": "Tester",
    "password": "TestPass123",
    "explorerType": "nature",
    "ageGroup": "adult_18_plus"
  }' | jq .
```

**Kết quả mong đợi:** HTTP 201, `accessToken` và `refreshToken` trong response.

### 8.2 Login

```bash
TOKEN=$(curl -s -X POST https://api.aiwisdombattle.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123"}' \
  | jq -r '.accessToken')

echo "Token: $TOKEN"
```

### 8.3 Get profile

```bash
curl -s https://api.aiwisdombattle.com/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 8.4 List nodes

```bash
curl -s https://api.aiwisdombattle.com/api/v1/nodes \
  -H "Authorization: Bearer $TOKEN" | jq 'length'
# → số lượng node chưa xem
```

### 8.5 Start session

```bash
# Lấy nodeId từ /nodes
NODE_ID=$(curl -s https://api.aiwisdombattle.com/api/v1/nodes \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[0].id')

curl -s -X POST https://api.aiwisdombattle.com/api/v1/sessions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"nodeId\":\"$NODE_ID\"}" | jq .
```

### 8.6 Complete session

```bash
SESSION_ID=<sessionId từ bước trên>

curl -s -X POST https://api.aiwisdombattle.com/api/v1/sessions/complete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"sessionId\":\"$SESSION_ID\",
    \"score\":80,
    \"durationSeconds\":240
  }" | jq .
# → adaptiveScore, nextSuggestions (3 nodes)
```

### 8.7 Knowledge map

```bash
curl -s "https://api.aiwisdombattle.com/api/v1/nodes/$NODE_ID/map" \
  -H "Authorization: Bearer $TOKEN" | jq 'length'
```

### 8.8 Bảng tổng hợp kết quả smoke test

| Endpoint | Method | Expected status | Kết quả |
|---|---|---|---|
| `/api/v1/auth/register` | POST | 201 | |
| `/api/v1/auth/login` | POST | 200 | |
| `/api/v1/auth/me` | GET | 200 | |
| `/api/v1/auth/refresh` | POST | 200 | |
| `/api/v1/auth/logout` | POST | 204 | |
| `/api/v1/nodes` | GET | 200 (array) | |
| `/api/v1/nodes/:id` | GET | 200 (6-stage) | |
| `/api/v1/nodes/:id/map` | GET | 200 (array) | |
| `/api/v1/nodes/:id/deep-dive` | GET | 200 (array) | |
| `/api/v1/nodes/:id/cross-domain` | GET | 200 (array) | |
| `/api/v1/sessions` | POST | 200 | |
| `/api/v1/sessions/complete` | POST | 200 (adaptive + suggestions) | |
| `/health` | GET | 200 `{"status":"UP"}` | |

---

## 9. Smoke Test Frontend

### 9.1 Kiểm tra Cloudflare Pages URL

Truy cập `https://ai-wisdom-battle.pages.dev` (hoặc custom domain nếu đã cấu hình).

### 9.2 Checklist UI

- [ ] Trang chủ load bình thường (không có lỗi network trong console)
- [ ] Form đăng ký → đăng ký thành công
- [ ] Form đăng nhập → đăng nhập thành công, token lưu vào localStorage
- [ ] Danh sách node hiển thị (gọi `/api/v1/nodes`)
- [ ] Click vào node → hiển thị 6 giai đoạn
- [ ] Hoàn thành session → thấy `nextSuggestions`
- [ ] Knowledge map render đúng

### 9.3 Kiểm tra Network tab (browser DevTools)

- Tất cả API call đến `https://api.aiwisdombattle.com/api/v1/...`
- Response headers có `Access-Control-Allow-Origin` đúng
- Không có `Mixed Content` warning (toàn HTTPS)

---

## 10. Rollback

### Nếu Go backend lỗi, rollback về image trước

```bash
# Xem lịch sử image
docker image ls ghcr.io/aiwisdombattle/backend-go

# Rollback về SHA cụ thể
IMAGE_TAG=<old-sha> docker compose -f docker-compose.prod.yml up -d app
```

### Nếu migration data lỗi

```bash
# Không cần roll back PostgreSQL — chỉ cần rerun import script
# Oracle VM cũ với Neo4j vẫn còn hoạt động
python3 scripts/migrate-neo4j-to-pg.py --csv-dir ./migration-export
```

### Nếu muốn quay về Oracle VM cũ hoàn toàn

1. DNS: trỏ `api.aiwisdombattle.com` về IP Oracle VM (CNAME hoặc A record)
2. Cloudflare: đổi record type
3. Oracle VM Spring Boot vẫn còn chạy → production không mất service

### Hủy Lightsail nếu cần

```bash
# Hủy instance (trong 3 tháng free trial = không mất tiền)
aws lightsail delete-instance \
  --instance-name awb-prod \
  --region ap-southeast-1
```

---

## 11. Checklist cuối ngày

### Infrastructure

- [ ] Lightsail instance `awb-prod` đang `running`
- [ ] SSH kết nối được qua IPv6
- [ ] Docker, docker-compose hoạt động trên instance
- [ ] UFW firewall: 22, 80, 443 TCP/UDP open

### Cloudflare

- [ ] AAAA record `api.aiwisdombattle.com` → IPv6 Lightsail
- [ ] Proxy mode ON (orange cloud)
- [ ] SSL/TLS mode: Full (strict)
- [ ] Cloudflare Pages deploy thành công

### GitHub

- [ ] Secrets: `LIGHTSAIL_HOST`, `LIGHTSAIL_SSH_KEY`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`
- [ ] Variable: `VITE_API_BASE_URL`
- [ ] GHCR write permission bật

### Data Migration

- [ ] Neo4j export: `knowledge_nodes.csv` và `node_relations.csv` có dữ liệu
- [ ] PostgreSQL import: không có lỗi
- [ ] SQL verify: số lượng node và relation khớp với Neo4j

### Production

- [ ] `docker compose -f docker-compose.prod.yml ps` → tất cả `healthy`
- [ ] `/health` trả `{"status":"UP"}`
- [ ] Toàn bộ 13 endpoints smoke test pass
- [ ] Frontend kết nối backend end-to-end

### Sau khi live

- [ ] Setup daily backup: `pg_dump` cron → local storage hoặc S3
- [ ] Setup Lightsail snapshot (1 tuần/lần)
- [ ] Merge branch vào master (sau khi verify ổn định)

---

## Phụ lục: Lệnh hữu ích

```bash
# Xem log realtime
docker compose -f docker-compose.prod.yml logs -f app

# Restart app
docker compose -f docker-compose.prod.yml restart app

# Exec vào container
docker compose -f docker-compose.prod.yml exec app sh

# Xem RAM usage
docker stats --no-stream

# Backup PostgreSQL
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U postgres ai_wisdom_battle > backup-$(date +%Y%m%d).sql

# Reload Caddy config
docker compose -f docker-compose.prod.yml exec caddy \
  caddy reload --config /etc/caddy/Caddyfile

# Kiểm tra TLS cert
echo | openssl s_client -connect api.aiwisdombattle.com:443 2>&1 | grep -E "subject|issuer|expire"
```

---

*Cập nhật lần cuối: 2026-03-23*
