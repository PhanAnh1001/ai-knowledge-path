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
4. [Cấu hình Cloudflare](#3-cấu-hình-cloudflare) — DNS, SSL, API Token, Pages
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
# Tạo key pair RSA 4096-bit (Lightsail ImportKeyPair chỉ hỗ trợ RSA, không hỗ trợ ed25519)
ssh-keygen -t rsa -b 4096 -C "awb-lightsail-deploy" -f ~/.ssh/awb-lightsail

# Kết quả:
#   ~/.ssh/awb-lightsail      ← private key (KHÔNG share, lưu an toàn)
#   ~/.ssh/awb-lightsail.pub  ← public key  (sẽ upload qua GitHub Secret)
```

> **Lưu ý quan trọng:** AWS Lightsail API (`ImportKeyPair`) chỉ chấp nhận **RSA key**. Dùng ed25519 sẽ báo lỗi `InvalidInputException: The value for publicKeyBase64 isn't valid`.

### 1.2 Lấy AWS Access Key

1. Đăng nhập [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. **Users** → chọn user của bạn → **Security credentials**
3. **Access keys** → **Create access key** → chọn use case **CLI**
4. Lưu lại `Access key ID` và `Secret access key` — chỉ hiển thị **một lần**!

> Nếu chưa có IAM user: **IAM** → **Users** → **Create user** → gán policy `LightsailFullAccess` (tạo theo bước 1.2.1 bên dưới nếu chưa có).

### 1.2.1 Tạo IAM policy LightsailFullAccess (nếu chưa có)

AWS **không có** managed policy tên `AmazonLightsailFullAccess` sẵn — cần tạo **customer managed policy** thủ công:

1. Truy cập [AWS IAM Console](https://console.aws.amazon.com/iam/) → **Policies** → **Create policy**
2. Chọn tab **JSON**, dán nội dung sau:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LightsailFullAccess",
      "Effect": "Allow",
      "Action": "lightsail:*",
      "Resource": "*"
    }
  ]
}
```

3. Nhấn **Next** → đặt tên policy: `LightsailFullAccess` → **Create policy**
4. Quay lại **Users** → chọn user → **Add permissions** → **Attach policies directly** → tìm `LightsailFullAccess` → tick chọn → **Add permissions**

> **Tại sao chỉ `lightsail:*`?** Terraform provider Lightsail chỉ cần quyền Lightsail API — không cần EC2, S3, hay bất kỳ service nào khác. Giới hạn scope giảm rủi ro nếu key bị lộ.

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

> **Không dùng lại SSH key của Oracle Cloud.** Oracle Cloud dùng ed25519, còn Lightsail yêu cầu RSA — phải tạo key riêng theo bước 1.1.

### 1.4 Chạy Terraform Plan (review trước khi apply)

1. Truy cập **GitHub repo** → tab **Actions**
2. Chọn workflow **"Terraform (AWS Lightsail)"**
3. Nhấn **"Run workflow"** → chọn branch `claude/lightsail-migration-gBk3t` → **action: `plan`** (mặc định) → **Run workflow**
4. Chờ workflow hoàn thành (~1 phút)

**Xem kết quả Plan:**

Trong log của step **"Terraform Plan"**, kiểm tra dòng tóm tắt:

```
Plan: 3 to add, 0 to change, 0 to destroy.
```

> **Quan trọng:** Review kỹ danh sách resources trước khi tiếp tục. Nếu thấy `to destroy` hoặc `to change` không mong đợi — dừng lại, kiểm tra `infra/lightsail/` trước khi apply. Plan không tạo resource nào, hoàn toàn an toàn để chạy nhiều lần.

### 1.5 Chạy Terraform Apply trên GitHub Actions

Sau khi đã xác nhận Plan ở bước 1.4 đúng như kỳ vọng:

1. Truy cập **GitHub repo** → tab **Actions**
2. Chọn workflow **"Terraform (AWS Lightsail)"**
3. Nhấn **"Run workflow"** → chọn branch `claude/lightsail-migration-gBk3t` → **action: `apply`** → **Run workflow**
4. Chờ workflow hoàn thành (~3 phút)

**Xem kết quả:**

Trong log của step **"Terraform Output"**, bạn sẽ thấy:
```
public_ip_address = "54.251.xxx.xxx"
instance_name = "awb-prod"
ssh_command = "ssh -i ~/.ssh/awb-lightsail ubuntu@54.251.xxx.xxx"
```

> **Lưu lại public IP** — dùng ở bước 3 (Cloudflare A record) và bước 4 (GitHub Secret `LIGHTSAIL_HOST`).

**Terraform đã tự động:**
- Upload SSH public key → `awb-deploy-key`
- Tạo instance Ubuntu 24.04 · `small_3_0` · 2vCPU · 2GB · $10/tháng · IPv4
- Chạy `lightsail-init.sh` khi boot (cài Docker, clone repo, cấu hình firewall)
- Mở firewall ports: TCP 22/80/443 và UDP 443

### 1.6 SSH vào instance lần đầu

```bash
# Thay <IP> bằng địa chỉ lấy từ Terraform output
ssh -i ~/.ssh/awb-lightsail ubuntu@<IP>
```

---

## 2. Bootstrap Instance

> `lightsail-init.sh` đã được chạy tự động qua `--user-data`. Kiểm tra trạng thái:

```bash
# SSH vào instance
ssh -i ~/.ssh/awb-lightsail ubuntu@<IP>

# Kiểm tra cloud-init đã hoàn thành
sudo cloud-init status
# → status: done

# Kiểm tra Docker đang chạy
sudo systemctl status docker
docker --version

# Kiểm tra repo đã clone
ls /opt/ai-knowledge-path/

# Kiểm tra .env placeholder đã tạo
cat /opt/ai-knowledge-path/.env
```

### 2.1 File .env — tự động từ GitHub Secrets

> **Không cần SSH vào server để sửa `.env` thủ công.** Deploy workflow tự động tạo `.env` từ GitHub Secrets mỗi khi chạy (xem bước 4).

File `.env` được inject tự động với nội dung sau:

| Biến | Nguồn |
|---|---|
| `POSTGRES_DB`, `POSTGRES_USER` | Hardcoded trong workflow |
| `POSTGRES_PASSWORD` | GitHub Secret `POSTGRES_PASSWORD` |
| `DATABASE_URL` | Tự động ghép từ `POSTGRES_PASSWORD` |
| `JWT_SECRET` | GitHub Secret `JWT_SECRET` |
| `CORS_ALLOWED_ORIGINS` | GitHub Variable `CORS_ALLOWED_ORIGINS` |
| `CLOUDFLARE_API_TOKEN` | GitHub Secret `CLOUDFLARE_API_TOKEN` |

Để thay đổi secret: cập nhật GitHub Secret rồi trigger deploy lại — file `.env` trên server sẽ được ghi đè tự động.

Nếu cần kiểm tra `.env` đã được tạo đúng (không xem nội dung):
```bash
ssh -i ~/.ssh/awb-lightsail ubuntu@<IP>
wc -l /opt/ai-knowledge-path/.env   # phải là 14 dòng
ls -la /opt/ai-knowledge-path/.env  # phải là -rw------- (600)
```

---

## 3. Cấu hình Cloudflare

> **Tổng quan:** Cloudflare đảm nhận 3 vai trò trong hệ thống:
> 1. **DNS + proxy** cho API backend (`api.example.com` → Lightsail)
> 2. **TLS certificate** tự động cho Caddy qua DNS-01 challenge
> 3. **Hosting frontend** React app qua Cloudflare Pages (miễn phí)
>
> **Lưu ý:** Tài liệu này dùng `example.com` làm placeholder. Thay bằng domain thật của bạn ở mọi nơi.

> **Chưa có domain?**
>
> Custom domain là bắt buộc để backend có HTTPS đúng nghĩa. Không có HTTPS, frontend (`https://*.pages.dev`) sẽ bị lỗi **Mixed Content** khi gọi API qua HTTP.
>
> **Các lựa chọn:**
> - **Mua domain** (~$10/năm tại Cloudflare Registrar, Namecheap) — khuyến nghị cho production
> - **Dùng `sslip.io` để test** (miễn phí, không cần đăng ký): `<LIGHTSAIL-IP>.sslip.io` tự động resolve về IP đó, Caddy lấy cert qua ACME HTTP-01. Ví dụ: `54.251.1.2.sslip.io`
>   - Set `API_DOMAIN=54.251.1.2.sslip.io` trong GitHub Variables
>   - Xoá block `tls { dns cloudflare ... }` khỏi `Caddyfile` (Caddy sẽ dùng HTTP-01 tự động)
>   - `CLOUDFLARE_API_TOKEN` vẫn cần cho Cloudflare Pages deploy, nhưng KHÔNG cần quyền `Zone → DNS → Edit`

### 3.1 Đăng nhập và chọn domain

1. Truy cập [dash.cloudflare.com](https://dash.cloudflare.com) và đăng nhập
2. Trên trang chủ dashboard, click vào domain `example.com` trong danh sách

> **Domain chưa có trong Cloudflare?** Vào **Add a Site** → nhập domain → chọn Free plan → Cloudflare sẽ scan DNS hiện tại → cập nhật nameservers tại nhà đăng ký domain (GoDaddy/Namecheap/...) theo hướng dẫn.

### 3.2 Thêm DNS record cho backend API

Từ trang domain, vào **DNS** → **Records** → nhấn **Add record**:

| Field | Giá trị | Lưu ý |
|---|---|---|
| Type | `A` | |
| Name | `api` | → tạo subdomain `api.example.com` |
| IPv4 address | `54.251.xxx.xxx` | Public IP từ Terraform output (bước 1.4) |
| Proxy status | **Proxied** | Click icon cloud để bật — phải là **cam** (không phải xám) |
| TTL | Auto | Chỉ có hiệu lực khi tắt proxy |

Nhấn **Save**.

> **Tại sao bật Proxy (cloud cam)?**
> - Ẩn IP thật của Lightsail → giảm rủi ro DDoS trực tiếp
> - SSL terminate tại Cloudflare edge; Cloudflare forward về Lightsail qua HTTPS
> - **Không bật proxy** (DNS only / cloud xám): IP Lightsail bị lộ, TLS do Caddy tự xử lý với Let's Encrypt trực tiếp — vẫn hoạt động nhưng mất lớp bảo vệ của Cloudflare

**Xác nhận:** Sau khi save, bảng DNS hiển thị dòng:
```
api   A   54.251.xxx.xxx   Proxied   Auto
```

### 3.3 Cấu hình SSL/TLS

Từ trang domain, vào **SSL/TLS** → **Overview** → chọn **Full (strict)**

| Chế độ | Ý nghĩa | Phù hợp không? |
|---|---|---|
| Off | Không có HTTPS | Không dùng |
| Flexible | HTTPS Cloudflare ↔ User, HTTP Cloudflare ↔ Origin | Không an toàn |
| Full | HTTPS cả 2 chiều, nhưng chấp nhận self-signed cert | Tạm ổn |
| **Full (strict)** | HTTPS cả 2 chiều, cert phải hợp lệ (CA-issued) | **Dùng cái này** |

> **Tại sao Full (strict)?** Caddy tự lấy cert từ Let's Encrypt qua DNS-01 challenge — cert hợp lệ, không phải self-signed → Full (strict) hoạt động. Đồng thời đảm bảo không có MITM giữa Cloudflare và Lightsail.

**Lưu ý:** Ở tab **Edge Certificates**, kiểm tra **Always Use HTTPS** đã bật (thường bật mặc định).

### 3.4 Tìm Cloudflare Account ID

Account ID dùng cho GitHub Secret `CLOUDFLARE_ACCOUNT_ID` (bước 4) và trong Cloudflare Pages.

**Cách lấy:**
1. Trên [dash.cloudflare.com](https://dash.cloudflare.com), click vào domain bất kỳ
2. Nhìn vào **sidebar phải** → mục **Account ID** (cuộn xuống nếu không thấy ngay)
3. Copy chuỗi 32 ký tự hex, ví dụ: `a1b2c3d4e5f6789012345678901234ab`

Hoặc vào **Workers & Pages** → trang Overview → sidebar phải cũng hiển thị **Account ID**.

### 3.5 Tạo Cloudflare API Token

Token cần **hai quyền** cho hai mục đích khác nhau trong cùng một token:

| Mục đích | Quyền cần | Sử dụng bởi |
|---|---|---|
| Caddy lấy TLS cert tự động qua DNS-01 | `Zone → DNS → Edit` | Container `awb-caddy` trên Lightsail |
| Deploy React app lên Cloudflare Pages | `Account → Cloudflare Pages → Edit` | GitHub Actions workflow |

**Các bước tạo token:**

1. Click **avatar** góc trên phải → **My Profile** → tab **API Tokens**
2. Nhấn **Create Token** → chọn **Create Custom Token** (không dùng template)
3. Đặt tên: `ai-knowledge-path-prod`
4. Phần **Permissions** — nhấn **Add more** để thêm đủ **2 dòng**:

   | Resource | Permission |
   |---|---|
   | `Zone` → `DNS` | `Edit` |
   | `Account` → `Cloudflare Pages` | `Edit` |

5. Phần **Zone Resources** (xuất hiện sau khi thêm Zone permission):
   - Chọn **Specific zone** → chọn `example.com`
   - (Không chọn "All zones" — least privilege)

6. Nhấn **Continue to summary** → kiểm tra danh sách quyền:
   ```
   Zone - DNS - Edit - example.com
   Account - Cloudflare Pages - Edit - <tên account>
   ```
7. Nhấn **Create Token** → **copy token ngay** — chỉ hiển thị một lần

Token có dạng: `yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

> **Token bị lộ?** Vào **My Profile → API Tokens** → nhấn **Roll** (đổi giá trị giữ nguyên quyền) hoặc **Delete** → tạo mới.

Xem thêm chi tiết xử lý lỗi tại: [docs/CLOUDFLARE-TOKEN-SETUP.md](CLOUDFLARE-TOKEN-SETUP.md)

### 3.6 Cấu hình Cloudflare Pages (frontend)

#### 3.6.1 Tạo project Pages

1. Từ sidebar trái, vào **Workers & Pages** → tab **Pages**
2. Nhấn **Create application** → chọn tab **Pages** → **Connect to Git**
3. Chọn provider **GitHub** → authorize Cloudflare nếu lần đầu
4. Tìm và chọn repo `ai-knowledge-path` → nhấn **Begin setup**

#### 3.6.2 Cấu hình build

| Field | Value | Lưu ý |
|---|---|---|
| Project name | `ai-knowledge-path` | Tạo subdomain `ai-knowledge-path.pages.dev` |
| Production branch | `master` | Deploy lên production khi có push vào master |
| Framework preset | `None` (hoặc tự detect Vite) | |
| Build command | `npm run build` | |
| Build output directory | `dist` | Relative to root directory |
| Root directory | `frontend` | Quan trọng — không để trống |

#### 3.6.3 Thêm environment variable

Trong phần **Environment variables** → click **Add variable**:

| Variable name | Value | Environment |
|---|---|---|
| `VITE_API_BASE_URL` | `https://api.example.com/api/v1` | Production |

> **Lưu ý:** Biến `VITE_*` được Vite nhúng vào bundle lúc build — không phải runtime. Phải set ở đây (build time), không phải trên Lightsail.

#### 3.6.4 Deploy lần đầu

Nhấn **Save and Deploy** — Cloudflare sẽ build và deploy lần đầu (~2 phút).

Sau khi deploy xong:
- URL production: `https://ai-knowledge-path.pages.dev`
- Dashboard → **Workers & Pages** → `ai-knowledge-path` → tab **Deployments** để xem log

> **SPA routing hoạt động nhờ `_redirects`:** File `frontend/public/_redirects` (đã có trong repo) chứa `/* /index.html 200` — đảm bảo React Router hoạt động đúng khi truy cập trực tiếp URL như `/login`, `/battle`.

#### 3.6.5 Kết nối deploy workflow với Pages

Từ bước 4.1 trở đi, GitHub Actions dùng `cloudflare/pages-action@v1` để deploy. Cần đảm bảo:
- Secret `CLOUDFLARE_API_TOKEN` có quyền `Account → Cloudflare Pages → Edit` (bước 3.5)
- Secret `CLOUDFLARE_ACCOUNT_ID` khớp với Account ID (bước 3.4)
- `projectName: ai-knowledge-path` trong workflow khớp với tên project vừa tạo

> **Lần deploy từ CI (sau merge vào master):** Workflow chỉ định `branch: master` khi deploy → Cloudflare Pages nhận dạng đây là production deployment, không phải preview URL.

---

## 4. Cấu hình GitHub Secrets

### 4.1 Secrets cần tạo

Truy cập: **GitHub repo** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret name | Giá trị | Cách lấy | Dùng cho |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | Access key ID | IAM → Security credentials | Terraform Lightsail |
| `AWS_SECRET_ACCESS_KEY` | Secret access key | Cùng lúc tạo Access key | Terraform Lightsail |
| `SSH_PUBLIC_KEY` | Nội dung `~/.ssh/awb-lightsail.pub` | `cat ~/.ssh/awb-lightsail.pub` | Terraform (upload key) |
| `LIGHTSAIL_HOST` | Public IPv4 từ Terraform output | Bước 1.4 — workflow log | Deploy workflow |
| `LIGHTSAIL_SSH_KEY` | Nội dung `~/.ssh/awb-lightsail` | `cat ~/.ssh/awb-lightsail` | Deploy workflow (SSH) |
| `CLOUDFLARE_API_TOKEN` | Token từ bước 3.3 | Cloudflare dashboard | Caddy TLS + Deploy frontend |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID | Cloudflare → sidebar phải | Deploy frontend |
| `POSTGRES_PASSWORD` | Mật khẩu PostgreSQL mạnh | `openssl rand -base64 24` | Deploy → .env injection |
| `JWT_SECRET` | Khoá JWT (≥ 32 ký tự) | `openssl rand -base64 32` | Deploy → .env injection |

> **Thứ tự quan trọng:** Tạo `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `SSH_PUBLIC_KEY` **trước** khi chạy Terraform (bước 1.3). Tạo `LIGHTSAIL_HOST` **sau** khi có public IP từ Terraform output (bước 1.4). Tạo `POSTGRES_PASSWORD`, `JWT_SECRET` **trước** lần deploy đầu tiên.

### 4.2 Variables cần tạo

**Settings** → **Secrets and variables** → **Actions** → **Variables** → **New repository variable**

| Variable name | Giá trị |
|---|---|
| `API_DOMAIN` | `api.example.com` (hoặc `54.251.x.x.sslip.io` nếu không có domain) |
| `VITE_API_BASE_URL` | `https://api.example.com/api/v1` |
| `CORS_ALLOWED_ORIGINS` | `https://example.com,https://ai-knowledge-path.pages.dev` |

### 4.3 Dùng GitHub CLI (nhanh hơn)

```bash
# Login GitHub CLI
gh auth login

# Secrets cho Terraform Lightsail (tạo trước bước 1.3)
gh secret set AWS_ACCESS_KEY_ID      --body "<access-key-id>"
gh secret set AWS_SECRET_ACCESS_KEY  --body "<secret-access-key>"
gh secret set SSH_PUBLIC_KEY         < ~/.ssh/awb-lightsail.pub

# Secrets cho Deploy workflow (tạo sau bước 1.4 khi có public IP)
gh secret set LIGHTSAIL_HOST         --body "<IP-từ-terraform-output>"
gh secret set LIGHTSAIL_SSH_KEY      < ~/.ssh/awb-lightsail
gh secret set CLOUDFLARE_API_TOKEN   --body "<token>"
gh secret set CLOUDFLARE_ACCOUNT_ID  --body "<account_id>"
gh secret set POSTGRES_PASSWORD      --body "$(openssl rand -base64 24)"
gh secret set JWT_SECRET             --body "$(openssl rand -base64 32)"

# Variables
gh variable set API_DOMAIN           --body "api.example.com"
gh variable set VITE_API_BASE_URL    --body "https://api.example.com/api/v1"
gh variable set CORS_ALLOWED_ORIGINS --body "https://ai-knowledge-path.pages.dev"
```

### 4.4 Cấp quyền GHCR cho Actions

GitHub Container Registry (ghcr.io) dùng để lưu Docker image.

**Repo Settings** → **Actions** → **General** → **Workflow permissions** → chọn **Read and write permissions** → Save.

---

## 5. Build & Push Docker Image lần đầu

> CI pipeline sẽ tự build và push sau. Bước này là cho lần deploy đầu tiên thủ công.

```bash
# Trên máy local, tại thư mục gốc repo
cd /path/to/ai-knowledge-path

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
DATABASE_URL=postgres://postgres:<password>@<lightsail-ip>:5432/ai-knowledge-path
EOF
```

> **Lưu ý:** PostgreSQL trên Lightsail **không expose port 5432 ra ngoài** (chỉ accessible từ Docker internal network). Cần dùng SSH tunnel:

```bash
# Mở SSH tunnel: port 5433 local → port 5432 trên Lightsail (qua Docker)
ssh -i ~/.ssh/awb-lightsail \
  -L 5433:localhost:5432 \
  -N ubuntu@<IP> &

# Sau đó dùng DATABASE_URL qua tunnel
DATABASE_URL=postgres://postgres:<password>@localhost:5433/ai-knowledge-path
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
psql "postgres://postgres:<password>@localhost:5433/ai-knowledge-path"
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

> **Deploy được tự động hoá qua CI/CD.** Không cần SSH thủ công để pull image hay khởi động containers.

### 7.1 Trigger deploy lần đầu

Sau khi đã cấu hình đủ GitHub Secrets (bước 4):

**Cách 1 — Merge PR vào master** (khuyến nghị):
```bash
# Merge PR chứa code mới nhất vào master
# CI build image → Deploy workflow chạy tự động
```

**Cách 2 — Trigger thủ công** (nếu cần deploy ngay mà không cần CI):
1. **GitHub Actions** → **Deploy** → **Run workflow**
2. `deploy_target`: `both` · `dry_run`: `false`
3. Nhấn **Run workflow**

### 7.2 Workflow tự động thực hiện

```
[1/5] Login to GHCR
[2/5] Pull code (git reset --hard origin/master)
[3/5] Pull images: backend-go + caddy-cf
[4/5] Restart: postgres → app → caddy (3 containers)
[5/5] Health check: curl http://localhost:8080/health
```

### 7.3 Kiểm tra sau deploy

```bash
# SSH vào xem trạng thái containers
ssh -i ~/.ssh/awb-lightsail ubuntu@<IP>
docker compose -f /opt/ai-knowledge-path/docker-compose.prod.yml ps

# Output mong đợi:
# awb-postgres   running (healthy)
# awb-app        running (healthy)
# awb-caddy      running

# Kiểm tra HTTPS (sau khi Caddy lấy cert xong — có thể mất ~30s)
curl -s https://api.example.com/health
# → {"status":"UP"}
```

---

## 8. Smoke Test API

Chạy từ máy local (thay `<token>` sau khi register/login):

### 8.1 Register

```bash
curl -s -X POST https://api.example.com/api/v1/auth/register \
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
TOKEN=$(curl -s -X POST https://api.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123"}' \
  | jq -r '.accessToken')

echo "Token: $TOKEN"
```

### 8.3 Get profile

```bash
curl -s https://api.example.com/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 8.4 List nodes

```bash
curl -s https://api.example.com/api/v1/nodes \
  -H "Authorization: Bearer $TOKEN" | jq 'length'
# → số lượng node chưa xem
```

### 8.5 Start session

```bash
# Lấy nodeId từ /nodes
NODE_ID=$(curl -s https://api.example.com/api/v1/nodes \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[0].id')

curl -s -X POST https://api.example.com/api/v1/sessions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"nodeId\":\"$NODE_ID\"}" | jq .
```

### 8.6 Complete session

```bash
SESSION_ID=<sessionId từ bước trên>

curl -s -X POST https://api.example.com/api/v1/sessions/complete \
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
curl -s "https://api.example.com/api/v1/nodes/$NODE_ID/map" \
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

Truy cập `https://ai-knowledge-path.pages.dev` (hoặc custom domain nếu đã cấu hình).

### 9.2 Checklist UI

- [ ] Trang chủ load bình thường (không có lỗi network trong console)
- [ ] Form đăng ký → đăng ký thành công
- [ ] Form đăng nhập → đăng nhập thành công, token lưu vào localStorage
- [ ] Danh sách node hiển thị (gọi `/api/v1/nodes`)
- [ ] Click vào node → hiển thị 6 giai đoạn
- [ ] Hoàn thành session → thấy `nextSuggestions`
- [ ] Knowledge map render đúng

### 9.3 Kiểm tra Network tab (browser DevTools)

- Tất cả API call đến `https://api.example.com/api/v1/...`
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

1. DNS: trỏ `api.example.com` về IP Oracle VM (CNAME hoặc A record)
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
- [ ] SSH kết nối được qua IPv4
- [ ] Docker, docker-compose hoạt động trên instance
- [ ] UFW firewall: 22, 80, 443 TCP/UDP open

### Cloudflare

- [ ] A record `api.example.com` → public IPv4 Lightsail (bỏ qua nếu dùng sslip.io)
- [ ] Proxy mode ON (orange cloud)
- [ ] SSL/TLS mode: Full (strict)
- [ ] Cloudflare Pages deploy thành công

### GitHub

- [ ] Secrets: `LIGHTSAIL_HOST`, `LIGHTSAIL_SSH_KEY`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `POSTGRES_PASSWORD`, `JWT_SECRET`
- [ ] Variables: `API_DOMAIN`, `VITE_API_BASE_URL`, `CORS_ALLOWED_ORIGINS`
- [ ] GHCR write permission bật

### Data Migration

- [ ] Neo4j export: `knowledge_nodes.csv` và `node_relations.csv` có dữ liệu
- [ ] PostgreSQL import: không có lỗi
- [ ] SQL verify: số lượng node và relation khớp với Neo4j

### Production

- [ ] `docker compose -f docker-compose.prod.yml ps` → `awb-postgres`, `awb-app`, `awb-caddy` đang chạy
- [ ] `http://localhost:8080/health` trả `{"status":"UP"}`
- [ ] `https://api.example.com/health` trả `{"status":"UP"}` (HTTPS cert valid)
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
  pg_dump -U postgres ai-knowledge-path > backup-$(date +%Y%m%d).sql

# Reload Caddy config
docker compose -f docker-compose.prod.yml exec caddy \
  caddy reload --config /etc/caddy/Caddyfile

# Kiểm tra TLS cert
echo | openssl s_client -connect api.example.com:443 2>&1 | grep -E "subject|issuer|expire"
```

---

*Cập nhật lần cuối: 2026-03-25 — mở rộng section 3 Cloudflare với hướng dẫn chi tiết DNS, SSL, API Token, Pages*
