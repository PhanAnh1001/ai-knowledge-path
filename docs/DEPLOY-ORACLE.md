# Deploy Production — Oracle Cloud Always Free

Toàn bộ stack chạy trên **1 ARM VM miễn phí mãi mãi** (không hết hạn như AWS Free Tier).

## Kiến trúc

```
Internet :443/:80
     │
     ▼
Oracle Cloud ARM A1 (4 OCPU · 24 GB RAM · 100 GB disk)
├── Caddy :443/:80    auto-SSL Let's Encrypt · serve frontend · proxy /api/*
├── Spring Boot :8080              (4 GB mem_limit)
├── Python Engine :8001            (1 GB mem_limit)
├── PostgreSQL 16 :5432 [internal] (2 GB mem_limit)
├── Neo4j 5.18 :7687 [internal]   (4 GB mem_limit · heap 1.5G + pagecache 1G)
└── Redis 7 :6379 [internal]       (512 MB mem_limit)
                           Tổng ~12 GB / 24 GB — còn buffer thoải mái
```

## Phân bố file trong repo

```
infra/oracle/
├── main.tf                  # Tạo VCN + subnet + security list + ARM instance
├── variables.tf             # Input variables
├── outputs.tf               # Public IP, SSH command
├── cloud-init.yml           # Bootstrap VM: Docker, Node, UFW, deploy user
└── terraform.tfvars.example # Template credentials OCI

docker-compose.prod.yml      # Production compose (chạy trên Oracle VM)
Caddyfile                    # Reverse proxy config
.github/workflows/deploy.yml # CI/CD: SSH deploy sau khi tests pass
```

---

## Phần A — Tạo VM qua Oracle Cloud Web Console (chi tiết từng bước)

### A1. Đăng ký Oracle Cloud Always Free

1. Vào [signup.oracle.com/cloud/free](https://signup.oracle.com/cloud/free)
2. Điền email, chọn region **gần nhất** (Singapore, Tokyo, Sydney...)
3. Điền thẻ tín dụng (xác minh, không bị tính tiền nếu dùng Always Free resources)
4. Sau khi active: truy cập [console.oracle.com](https://console.oracle.com)

### A2. Tạo VCN (Virtual Cloud Network)

1. Menu ☰ → **Networking** → **Virtual Cloud Networks**
2. Chọn đúng region (góc trên phải)
3. Nhấn **Start VCN Wizard**
4. Chọn **"Create VCN with Internet Connectivity"** → **Start VCN Wizard**
5. Điền:
   - **VCN name**: `awb-vcn`
   - Các ô khác để mặc định
6. Nhấn **Next** → **Create**

### A3. Mở ports trong Security List

Sau khi tạo VCN, Security List mặc định chỉ cho phép SSH (port 22). Cần thêm port 80 và 443:

1. Vào VCN `awb-vcn` vừa tạo
2. Sidebar trái → **Security Lists** → nhấn vào `Default Security List for awb-vcn`
3. Tab **Ingress Rules** → **Add Ingress Rules**:

   **Rule 1 — HTTP:**
   | Trường | Giá trị |
   |---|---|
   | Source CIDR | `0.0.0.0/0` |
   | IP Protocol | `TCP` |
   | Destination Port Range | `80` |
   | Description | `HTTP Caddy` |

4. **Add Ingress Rules** lần 2 — **HTTPS:**
   | Trường | Giá trị |
   |---|---|
   | Source CIDR | `0.0.0.0/0` |
   | IP Protocol | `TCP` |
   | Destination Port Range | `443` |
   | Description | `HTTPS Caddy` |

5. Nhấn **Add Ingress Rules** để lưu

### A4. Tạo SSH Key

Nếu chưa có SSH key:

```bash
# Trên máy local
ssh-keygen -t ed25519 -C "oracle-awb" -f ~/.ssh/oracle_awb
# Tạo ra 2 file:
#   ~/.ssh/oracle_awb       ← private key (giữ bí mật)
#   ~/.ssh/oracle_awb.pub   ← public key (dán vào Oracle Console)
```

### A5. Tạo ARM A1 Instance

1. Menu ☰ → **Compute** → **Instances**
2. Nhấn **Create Instance**
3. Điền các thông số:

   **Name**: `awb-server`

   **Image** (nhấn **Change image**):
   - Tab **Canonical Ubuntu**
   - Chọn **Ubuntu 22.04 Minimal aarch64** (có label `aarch64`)
   - Nhấn **Select Image**

   **Shape** (nhấn **Change shape**):
   - Tab **Ampere** (ARM)
   - Shape: **VM.Standard.A1.Flex**
   - OCPU count: **4**
   - Memory (GB): **24**
   - Nhấn **Select shape**

   **Networking**:
   - VCN: `awb-vcn`
   - Subnet: `Public Subnet-awb-vcn`
   - Public IP: **Assign a public IPv4 address** ✅

   **Add SSH keys**:
   - Chọn **Paste public keys**
   - Dán nội dung file `~/.ssh/oracle_awb.pub`

   **Boot volume**:
   - Nhấn **Show advanced options** → **Boot volume**
   - Size: `100 GB` (hoặc để mặc định 47GB, tối đa 200GB free)

4. Nhấn **Create**. VM khởi động mất ~2 phút.

5. Sau khi status = **Running**, lấy **Public IP address** (hiện trong trang Instance details).

### A6. Chờ cloud-init hoàn tất

```bash
# SSH vào VM với user ubuntu
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>

# Xem cloud-init đang chạy
sudo tail -f /var/log/cloud-init-output.log
# Chờ đến khi thấy: "=== cloud-init DONE. ==="  (~3-5 phút)
```

> **Lưu ý Oracle Cloud firewall**: Ubuntu 22.04 trên Oracle Cloud có thêm `iptables` rules mặc định block traffic. Sau khi SSH vào, chạy lệnh này để xóa:
> ```bash
> sudo iptables -F
> sudo netfilter-persistent save 2>/dev/null || true
> ```

### A7. Cấu hình `.env` trên VM

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>
sudo nano /opt/ai-knowledge-path/.env
```

Sửa các giá trị sau (thay `change_me_*` bằng giá trị thật):

```bash
# PostgreSQL
POSTGRES_DB=ai-knowledge-path
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<mật_khẩu_mạnh>

# Neo4j
NEO4J_USER=neo4j
NEO4J_PASSWORD=<mật_khẩu_mạnh_ít_nhất_8_ký_tự>

# Redis
REDIS_PASSWORD=<mật_khẩu_mạnh>

# JWT (ít nhất 32 ký tự)
JWT_SECRET=$(openssl rand -base64 48)

# Adaptive Engine
INTERNAL_API_KEY=$(openssl rand -base64 32)

# Spring Boot — PHẢI là prod
SPRING_PROFILES_ACTIVE=prod

# CORS: đặt địa chỉ website của bạn (biết sau khi Caddy chạy)
CORS_ALLOWED_ORIGINS=https://<PUBLIC_IP>.sslip.io

# Caddy site address
SITE_ADDRESS=<PUBLIC_IP>.sslip.io
```

> Tạo mật khẩu nhanh: `openssl rand -base64 24`

### A8. Khởi động services

```bash
# Chuyển sang user deploy
sudo -u deploy bash
cd /opt/ai-knowledge-path

# Khởi động toàn bộ stack (frontend trên Cloudflare Pages, không cần build ở đây)
docker compose -f docker-compose.prod.yml up -d

# Xem tiến trình khởi động (Neo4j cần ~30 giây)
docker compose -f docker-compose.prod.yml logs -f
```

### A9. Seed Neo4j (chỉ lần đầu)

```bash
# Chạy seeder một lần (tự tắt sau khi seed xong)
docker compose -f docker-compose.prod.yml run --rm neo4j-seeder
```

### A10. Kiểm tra

```bash
# Health check backend
curl http://localhost:8080/actuator/health
# {"status":"UP"}

# Health check engine
curl http://localhost:8001/health
# {"status":"ok"}

# Website (qua Caddy)
curl -I https://<PUBLIC_IP>.sslip.io
# HTTP/2 200 (Caddy đã cấp SSL tự động)
```

Mở trình duyệt: `https://<PUBLIC_IP>.sslip.io`

---

## Phần B — Tạo VM bằng Terraform (tự động hóa hoàn toàn)

### B1. Cài Terraform và OCI CLI

```bash
# Terraform
curl -fsSL https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip -o tf.zip
unzip tf.zip && sudo mv terraform /usr/local/bin/

# OCI CLI
bash -c "$(curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
oci setup config    # tạo API key, điền OCID, region
```

### B2. Tạo OCI API Key

1. Chạy `oci setup config` → làm theo hướng dẫn → tạo file `~/.oci/oci_api_key.pem`
2. Hoặc thủ công: OCI Console → **Profile** → **User settings** → **API Keys** → **Add API Key**
3. Upload public key PEM, copy fingerprint

### B3. Cấu hình Terraform

```bash
cd infra/oracle
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars    # điền tenancy_ocid, user_ocid, fingerprint, ssh_public_key...
```

### B4. Deploy infra

```bash
terraform init
terraform plan           # xem trước sẽ tạo gì
terraform apply          # gõ "yes" để xác nhận

# Lấy IP
terraform output public_ip
terraform output ssh_command
```

### B5. Tiếp tục từ bước A6

Sau khi có IP từ Terraform output, làm tiếp các bước A6 → A10.

---

## Phần C — CI/CD tự động (GitHub Actions)

### C1. Tạo SSH key riêng cho GitHub Actions

```bash
# Trên máy local — tạo key mới dành riêng cho CI/CD
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy -N ""

cat ~/.ssh/github_deploy.pub    # copy nội dung này
```

### C2. Thêm public key vào VM

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>

# Thêm vào authorized_keys của user deploy
echo "ssh-ed25519 AAAA... github-actions-deploy" \
  | sudo tee -a /home/deploy/.ssh/authorized_keys

# Kiểm tra
cat /home/deploy/.ssh/authorized_keys
```

### C3. Thêm secrets vào GitHub

**GitHub repo → Settings → Secrets and variables → Actions → Secrets:**

| Secret | Giá trị |
|---|---|
| `ORACLE_VM_IP` | Public IP của Oracle VM |
| `ORACLE_SSH_KEY` | Nội dung file `~/.ssh/github_deploy` (private key) |
| `CLOUDFLARE_API_TOKEN` | CF → My Profile → API Tokens → Edit Cloudflare Pages |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare dashboard → bên phải màn hình chính |

**Tab Variables → New repository variable:**

| Variable | Giá trị |
|---|---|
| `VITE_API_BASE_URL` | `https://<PUBLIC_IP>.sslip.io/api/v1` |

### C4. Kích hoạt CI/CD

Push lên nhánh `master` → CI chạy tests → nếu pass → 2 jobs song song:
- `deploy-backend`: SSH vào Oracle VM, git pull + build + restart
- `deploy-frontend`: build React + deploy Cloudflare Pages

Kiểm tra: **GitHub repo → Actions → Deploy**

---

## Lệnh thường dùng trên VM

```bash
# SSH vào VM
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>
sudo -u deploy bash
cd /opt/ai-knowledge-path

# Xem trạng thái tất cả services
docker compose -f docker-compose.prod.yml ps

# Xem logs service cụ thể
docker compose -f docker-compose.prod.yml logs -f app
docker compose -f docker-compose.prod.yml logs -f caddy

# Restart service
docker compose -f docker-compose.prod.yml restart app

# Deploy thủ công (không qua GitHub Actions)
git pull origin master
docker compose -f docker-compose.prod.yml build app adaptive-engine
docker compose -f docker-compose.prod.yml up -d --no-deps app adaptive-engine caddy
# Frontend: tự deploy qua Cloudflare Pages khi push lên master

# Xem tài nguyên đang dùng
docker stats --no-stream
free -h
df -h
```

---

## Phần D — Tách Frontend lên Cloudflare Pages (CDN toàn cầu)

> Frontend chạy trên Cloudflare Pages (200+ PoP toàn cầu), Oracle VM chỉ phục vụ API.
> Kết quả: latency frontend giảm từ ~150ms xuống ~5ms, frontend không bị ảnh hưởng khi VM restart.

### D1. Tạo project Cloudflare Pages

1. Đăng nhập [dash.cloudflare.com](https://dash.cloudflare.com)
2. Sidebar trái → **Workers & Pages** → tab **Pages** → **Create a project**
3. **Connect to Git** → chọn repo `ai-knowledge-path` → **Begin setup**
4. Điền build settings:

   | Trường | Giá trị |
   |---|---|
   | **Project name** | `ai-knowledge-path` |
   | **Production branch** | `master` |
   | **Framework preset** | `Vite` |
   | **Build command** | `npm run build` |
   | **Build output directory** | `dist` |
   | **Root directory (/)** | `frontend` |

5. Mở **Environment variables** → **Add variable**:

   | Name | Value | Environment |
   |---|---|---|
   | `VITE_API_BASE_URL` | `https://<PUBLIC_IP>.sslip.io/api/v1` | Production |

6. **Save and Deploy** → chờ ~2 phút → lấy URL: `ai-knowledge-path.pages.dev`

### D2. Cập nhật CORS trên Oracle VM

Backend Spring Boot cần biết domain của frontend để cho phép CORS:

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>
sudo -u deploy nano /opt/ai-knowledge-path/.env
```

Sửa:
```bash
CORS_ALLOWED_ORIGINS=https://ai-knowledge-path.pages.dev
```

Restart backend:
```bash
sudo -u deploy bash -c "cd /opt/ai-knowledge-path && docker compose -f docker-compose.prod.yml restart app"
```

### D3. Kiểm tra

```bash
# Mở trình duyệt → https://ai-knowledge-path.pages.dev
# Mở DevTools → Network → kiểm tra /api/v1 requests về Oracle VM
# Không có CORS error → setup thành công
```

---

## Phần E — Backup PostgreSQL tự động (Oracle Object Storage)

> Oracle Object Storage Always Free: **20GB**, không hết hạn.

### E1. Tạo bucket trên Oracle Console

1. Menu ☰ → **Storage** → **Object Storage & Archive Storage**
2. Nhấn **Create Bucket**:
   - **Bucket Name**: `awb-backups`
   - Storage Tier: **Standard**
3. Nhấn **Create**

### E2. Cài OCI CLI trên VM

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>

# Cài OCI CLI
bash -c "$(curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Cấu hình (điền tenancy OCID, user OCID, region, tạo API key)
oci setup config
# Key pair được tạo tại ~/.oci/oci_api_key.pem và ~/.oci/oci_api_key_public.pem

# Upload public key lên OCI Console:
# Profile → User settings → API Keys → Add API Key → Paste public key PEM
cat ~/.oci/oci_api_key_public.pem
```

### E3. Test upload

```bash
echo "test" > /tmp/test.txt
oci os object put --bucket-name awb-backups --file /tmp/test.txt --name test/test.txt
# Kiểm tra trên OCI Console → Object Storage → awb-backups
```

### E4. Setup cron backup hàng ngày

```bash
# Với user deploy (chạy docker commands)
sudo -u deploy crontab -e
```

Thêm dòng sau:
```
# Backup PostgreSQL 2h sáng mỗi ngày
0 2 * * * /opt/ai-knowledge-path/scripts/backup.sh >> /var/log/awb-backup.log 2>&1
```

Kiểm tra ngay:
```bash
sudo -u deploy /opt/ai-knowledge-path/scripts/backup.sh
# Xem kết quả trên OCI Console → Object Storage → awb-backups → postgres/
```

### E5. Restore từ backup

```bash
# Tải backup về
oci os object get \
  --bucket-name awb-backups \
  --name "postgres/pg_20240101_020000.sql.gz" \
  --file /tmp/restore.sql.gz

# Restore
gunzip -c /tmp/restore.sql.gz \
  | docker exec -i awb-postgres \
    psql -U "$POSTGRES_USER" "$POSTGRES_DB"
```

---

## Khi có domain thật

1. Trỏ **A record** của domain về `<PUBLIC_IP>`
2. Cập nhật `.env` trên VM:
   ```bash
   SITE_ADDRESS=awb.example.com
   CORS_ALLOWED_ORIGINS=https://awb.example.com
   ```
3. Restart Caddy:
   ```bash
   docker compose -f docker-compose.prod.yml restart caddy
   ```
   Caddy tự động cấp SSL cert mới cho domain.

---

## Troubleshooting

### Port 80/443 không truy cập được?

Oracle Cloud có 2 lớp firewall. Kiểm tra cả 2:

```bash
# Lớp 1: OCI Security List (web console) — đã làm ở bước A3
# Lớp 2: iptables trong VM (Oracle Ubuntu có rule chặn mặc định)
sudo iptables -L INPUT --line-numbers
sudo iptables -F           # xóa tất cả rules
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save > /etc/iptables/rules.v4
# UFW đã được cloud-init cấu hình (22, 80, 443)
sudo ufw status
```

### Caddy không cấp được SSL?

```bash
docker compose -f docker-compose.prod.yml logs caddy | grep -i "error\|acme"
```

Nguyên nhân thường gặp:
- Domain chưa trỏ về IP (nếu dùng domain thật)
- Port 80 bị block (Caddy cần 80 để verify Let's Encrypt)
- `SITE_ADDRESS` trong `.env` chưa đúng

Khi chưa có domain, dùng `sslip.io`: đặt `SITE_ADDRESS=<IP>.sslip.io` (ví dụ: `140.238.1.100.sslip.io`).

### Neo4j không start?

Neo4j cần ít nhất 1GB RAM. Với 24GB VM thì không thiếu RAM, nhưng kiểm tra:

```bash
docker compose -f docker-compose.prod.yml logs neo4j | tail -20
```

Thường lỗi do `NEO4J_PASSWORD` quá ngắn (phải ≥ 8 ký tự) hoặc volume cũ từ dev có schema khác.

### Spring Boot OOM (Out of Memory)?

Tăng `mem_limit` trong `docker-compose.prod.yml` nếu cần, hoặc kiểm tra JVM heap:

```bash
docker exec awb-app env | grep JAVA_OPTS
```

---

## Chi phí

| Resource | Always Free | Giới hạn |
|---|---|---|
| VM.Standard.A1.Flex | ✅ Mãi mãi | 4 OCPU, 24 GB tổng |
| Block Storage | ✅ Mãi mãi | 200 GB tổng |
| Outbound Data | ✅ Mãi mãi | 10 TB/tháng |
| Public IP | ✅ Mãi mãi | 2 IP cho VM đang chạy |

**Chi phí: $0/tháng** — không có giới hạn 12 tháng như AWS.
