# Deploy với Terraform — AI Wisdom Battle (Oracle Cloud Always Free)

Hướng dẫn này triển khai toàn bộ hạ tầng Oracle Cloud bằng **Infrastructure as Code** —
một lệnh `terraform apply` tạo xong VCN, Security List, Subnet, và ARM VM.

> Xem hướng dẫn setup thủ công qua web console: [`DEPLOY-ORACLE.md`](./DEPLOY-ORACLE.md)

---

## Chạy Terraform ở đâu?

| Phương án | Yêu cầu | Phù hợp |
|---|---|---|
| **[GitHub Actions](#github-actions-không-cần-cài-gì)** | Chỉ cần tài khoản GitHub | Điện thoại, không muốn cài công cụ |
| **[Máy local](#chạy-terraform-trên-máy-local)** | Terraform + OCI CLI | Máy tính cá nhân |

---

## GitHub Actions — Không cần cài gì

Workflow `.github/workflows/terraform.yml` đã có sẵn. Chỉ cần cấu hình secrets trên GitHub rồi nhấn nút.

### Bước A — Cấu hình secrets

Vào **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**, thêm 7 secrets:

| Secret | Giá trị | Cách lấy |
|---|---|---|
| `OCI_TENANCY_OCID` | `ocid1.tenancy.oc1..xxx` | OCI Console → Profile → Tenancy |
| `OCI_USER_OCID` | `ocid1.user.oc1..xxx` | Profile → User settings → OCID |
| `OCI_FINGERPRINT` | `aa:bb:cc:...` | User settings → API Keys → fingerprint |
| `OCI_API_PRIVATE_KEY` | Toàn bộ nội dung file `.pem` | Download khi tạo API Key (bao gồm `-----BEGIN...-----END-----`) |
| `OCI_REGION` | `ap-singapore-1` | Region gần nhất |
| `OCI_COMPARTMENT_OCID` | Giống `OCI_TENANCY_OCID` | Root compartment = tenancy OCID |
| `SSH_PUBLIC_KEY` | `ssh-ed25519 AAAA...` | Nội dung file `~/.ssh/oracle_awb.pub` |

> Tạo SSH key nếu chưa có (chạy trên máy tính hoặc Cloud Shell):
> ```bash
> ssh-keygen -t ed25519 -C "oracle-awb" -f ~/.ssh/oracle_awb
> cat ~/.ssh/oracle_awb.pub   # copy giá trị này vào SSH_PUBLIC_KEY
> ```

### Bước B — Chạy từ GitHub UI (điện thoại được)

1. Vào tab **Actions** trong repo
2. Sidebar trái → **Terraform (Oracle Cloud)**
3. Nhấn **Run workflow**
4. Chọn action:
   - `plan` — xem trước, không tạo gì (an toàn, chạy trước)
   - `apply` — tạo hạ tầng thật
   - `destroy` — xóa toàn bộ hạ tầng
5. Nhấn **Run workflow** (nút xanh)

### Bước C — Xem kết quả

Nhấn vào run vừa tạo → job **Terraform apply** → bước **Terraform Output** để lấy Public IP:

```
public_ip    = "140.238.x.x"
ssh_command  = "ssh -i <key> ubuntu@140.238.x.x"
site_address = "140.238.x.x.sslip.io"
```

> **State file:** Sau mỗi lần `apply`/`destroy`, `terraform.tfstate` được lưu tự động vào **Actions → Artifacts** (giữ 90 ngày). Lần chạy sau sẽ tự tải về để Terraform biết infra hiện tại.

---

## Chạy Terraform trên máy local

## Mục lục

1. [Kiến trúc hạ tầng](#1-kiến-trúc-hạ-tầng)
2. [Yêu cầu trước khi bắt đầu](#2-yêu-cầu-trước-khi-bắt-đầu)
3. [Cài đặt công cụ](#3-cài-đặt-công-cụ)
4. [Lấy OCI credentials](#4-lấy-oci-credentials)
5. [Cấu hình Terraform](#5-cấu-hình-terraform)
6. [Chạy Terraform](#6-chạy-terraform)
7. [Sau khi Terraform hoàn tất](#7-sau-khi-terraform-hoàn-tất)
8. [Triển khai ứng dụng](#8-triển-khai-ứng-dụng)
9. [CI/CD tự động sau đó](#9-cicd-tự-động-sau-đó)
10. [Quản lý và cập nhật hạ tầng](#10-quản-lý-và-cập-nhật-hạ-tầng)
11. [Xóa toàn bộ hạ tầng](#11-xóa-toàn-bộ-hạ-tầng)
12. [Xử lý sự cố](#12-xử-lý-sự-cố)

---

## 1. Kiến trúc hạ tầng

Terraform tạo các tài nguyên sau trên Oracle Cloud:

```
Oracle Cloud (Always Free)
└── Compartment
    └── VCN: awb-vcn (10.0.0.0/16)
        ├── Internet Gateway: awb-igw
        ├── Route Table: awb-route-table  (0.0.0.0/0 → igw)
        ├── Security List: awb-security-list
        │   ├── Ingress  22/TCP   (SSH)
        │   ├── Ingress  80/TCP   (HTTP → Caddy)
        │   ├── Ingress 443/TCP   (HTTPS → Caddy)
        │   ├── Ingress ICMP 3,4  (Path MTU Discovery)
        │   └── Egress   all      (outbound tự do)
        └── Public Subnet: awb-public-subnet (10.0.1.0/24)
            └── VM: awb-server
                ├── Shape: VM.Standard.A1.Flex (ARM)
                ├── OCPU: 4  |  RAM: 24 GB  |  Disk: 100 GB
                ├── OS: Ubuntu 22.04 Minimal aarch64
                └── cloud-init: Docker, swap 4GB, UFW, user deploy, clone repo
```

**Chi phí: $0/tháng** — Always Free, không có giới hạn 12 tháng.

---

## 2. Yêu cầu trước khi bắt đầu

| Yêu cầu | Kiểm tra |
|---|---|
| Tài khoản Oracle Cloud (đã verify thẻ) | [signup.oracle.com/cloud/free](https://signup.oracle.com/cloud/free) |
| Terraform ≥ 1.5 | `terraform version` |
| OCI CLI | `oci --version` |
| SSH key pair | `ls ~/.ssh/` |

---

## 3. Cài đặt công cụ

### Terraform

```bash
# Linux (amd64)
TERRAFORM_VERSION="1.7.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o tf.zip
unzip tf.zip
sudo mv terraform /usr/local/bin/
rm tf.zip

# macOS (Homebrew)
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Kiểm tra
terraform version
# Terraform v1.7.5
```

### OCI CLI

```bash
# Linux / macOS
bash -c "$(curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Kiểm tra
oci --version
# Oracle Cloud Infrastructure CLI 3.x.x
```

### SSH key pair (nếu chưa có)

```bash
ssh-keygen -t ed25519 -C "oracle-awb" -f ~/.ssh/oracle_awb
# Tạo ra:
#   ~/.ssh/oracle_awb      ← private key (giữ bí mật)
#   ~/.ssh/oracle_awb.pub  ← public key (dán vào terraform.tfvars)
```

---

## 4. Lấy OCI credentials

Terraform cần 4 thông tin để xác thực với Oracle Cloud API.

### 4.1 Tenancy OCID

1. Đăng nhập [console.oracle.com](https://console.oracle.com)
2. Nhấn icon **Profile** (góc trên phải) → **Tenancy: \<tên-tenancy\>**
3. Copy **OCID** trong trang Tenancy Information

```
ocid1.tenancy.oc1..aaaaaaaaxxx...
```

### 4.2 User OCID

1. Nhấn icon **Profile** → **User settings**
2. Copy **OCID** trong trang User Details

```
ocid1.user.oc1..aaaaaaaaxxx...
```

### 4.3 Tạo API Key và lấy Fingerprint

1. Trang **User settings** → sidebar trái → **API Keys**
2. Nhấn **Add API Key** → chọn **Generate API Key Pair**
3. **Download Private Key** → lưu vào `~/.oci/oci_api_key.pem`
4. **Download Public Key** (hoặc copy nội dung) → nhấn **Add**
5. Copy **Fingerprint** hiện ra (dạng `aa:bb:cc:...`)

```bash
# Đặt permission đúng cho private key
chmod 600 ~/.oci/oci_api_key.pem
```

**Hoặc** dùng OCI CLI để tạo tự động:

```bash
oci setup config
# Hướng dẫn từng bước: nhập User OCID, Tenancy OCID, Region, tự tạo API key
# Config được lưu tại: ~/.oci/config
```

### 4.4 Compartment OCID

Với tài khoản cá nhân Always Free, **Compartment OCID = Tenancy OCID** (root compartment).

---

## 5. Cấu hình Terraform

### 5.1 Sao chép file template

```bash
cd infra/oracle
cp terraform.tfvars.example terraform.tfvars
```

### 5.2 Điền các giá trị vào terraform.tfvars

```bash
nano terraform.tfvars    # hoặc code terraform.tfvars
```

Nội dung cần điền:

```hcl
# ── OCI Credentials ──────────────────────────────────────────────────────────
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaaxxx..."      # bước 4.1
user_ocid    = "ocid1.user.oc1..aaaaaaaaxxx..."          # bước 4.2
fingerprint  = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"  # bước 4.3

# Đường dẫn private key OCI API (vừa tải về ở bước 4.3)
private_key_path = "~/.oci/oci_api_key.pem"

# Region gần nhất:
# ap-singapore-1 | ap-tokyo-1 | ap-sydney-1 | us-ashburn-1 | eu-frankfurt-1
region = "ap-singapore-1"

# Compartment = root compartment = tenancy_ocid (cho tài khoản cá nhân)
compartment_ocid = "ocid1.tenancy.oc1..aaaaaaaaxxx..."

# ── SSH Key để SSH vào VM ─────────────────────────────────────────────────────
# Nội dung file ~/.ssh/oracle_awb.pub
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... oracle-awb"

# ── Instance (Always Free: tối đa 4 OCPU tổng + 24GB RAM tổng) ───────────────
instance_ocpus     = 4
instance_memory_gb = 24
boot_volume_gb     = 100

# ── Domain (để trống nếu chưa có domain) ─────────────────────────────────────
# Để trống "" — sau khi VM tạo xong sẽ dùng dạng "<IP>.sslip.io"
# Nếu có domain thật: "awb.example.com"
site_address = ""
```

Lấy nhanh SSH public key:

```bash
cat ~/.ssh/oracle_awb.pub
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

### 5.3 Kiểm tra .gitignore

File `terraform.tfvars` chứa credentials — phải không được commit:

```bash
grep "terraform.tfvars" .gitignore
# terraform.tfvars  ← phải có dòng này
```

---

## 6. Chạy Terraform

```bash
cd infra/oracle
```

### 6.1 Khởi tạo (tải provider OCI)

```bash
terraform init
```

Output mong đợi:
```
Initializing provider plugins...
- Finding oracle/oci versions matching "~> 5.0"...
- Installing oracle/oci v5.x.x...
Terraform has been successfully initialized!
```

### 6.2 Xem trước những gì sẽ được tạo

```bash
terraform plan
```

Terraform sẽ liệt kê **8 resources** sẽ được tạo:
- `oci_core_vcn.awb_vcn`
- `oci_core_internet_gateway.awb_igw`
- `oci_core_route_table.awb_rt`
- `oci_core_security_list.awb_sl`
- `oci_core_subnet.awb_subnet`
- `oci_core_instance.awb_server`

Kiểm tra kỹ output trước khi apply.

### 6.3 Tạo hạ tầng

```bash
terraform apply
```

Terraform hỏi xác nhận:
```
Do you want to perform these actions? Enter a value:
```

Gõ `yes` và nhấn Enter.

Thời gian chờ: **3–5 phút** (VM khởi động + cloud-init chạy thêm 3–5 phút nữa).

### 6.4 Xem kết quả

```bash
terraform output
```

Output:
```
instance_id  = "ocid1.instance.oc1..."
public_ip    = "140.238.x.x"
site_address = "140.238.x.x.sslip.io"
ssh_command  = "ssh -i <đường-dẫn-private-key> ubuntu@140.238.x.x"
```

Lưu lại `public_ip` — cần dùng ở các bước tiếp theo.

---

## 7. Sau khi Terraform hoàn tất

### 7.1 Chờ cloud-init hoàn tất

cloud-init cần thêm **3–5 phút** sau khi VM running để cài Docker, clone repo, cấu hình UFW.

```bash
# SSH vào VM
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>

# Theo dõi cloud-init
sudo tail -f /var/log/cloud-init-output.log
# Chờ dòng: "=== cloud-init DONE. SSH: ubuntu@<PUBLIC_IP> ==="
```

### 7.2 Xóa iptables rules Oracle mặc định

Ubuntu 22.04 trên Oracle Cloud có iptables rules chặn traffic. Xóa chúng:

```bash
sudo iptables -F
sudo netfilter-persistent save 2>/dev/null || true
```

### 7.3 Kiểm tra cloud-init đã cài đủ công cụ

```bash
docker --version        # Docker version 26.x.x
docker compose version  # Docker Compose version v2.x.x
git --version           # git version 2.x.x
ls /opt/ai-wisdom-battle/ # thư mục repo đã được clone
```

---

## 8. Triển khai ứng dụng

### 8.1 Cấu hình .env trên VM

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>
sudo -u deploy nano /opt/ai-wisdom-battle/.env
```

Điền các giá trị sau (thay placeholder bằng giá trị thật):

```dotenv
# PostgreSQL (chạy trong Docker trên VM)
POSTGRES_DB=ai_wisdom_battle
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<mật_khẩu_mạnh>

# Neo4j (chạy trong Docker trên VM)
NEO4J_USER=neo4j
NEO4J_PASSWORD=<tối_thiểu_8_ký_tự>

# Redis (chạy trong Docker trên VM)
REDIS_PASSWORD=<mật_khẩu_mạnh>

# JWT — bắt buộc ≥ 32 ký tự
JWT_SECRET=<chạy: openssl rand -base64 48>

# Internal API key giữa backend và adaptive-engine
INTERNAL_API_KEY=<chạy: openssl rand -base64 32>

# Spring Boot profile
SPRING_PROFILES_ACTIVE=prod

# Caddy SSL — dùng sslip.io nếu chưa có domain
SITE_ADDRESS=<PUBLIC_IP>.sslip.io
CORS_ALLOWED_ORIGINS=https://<PUBLIC_IP>.sslip.io
```

Tạo passwords nhanh:

```bash
openssl rand -base64 24   # password ~32 ký tự
openssl rand -base64 48   # JWT secret ~64 ký tự
```

### 8.2 Khởi động toàn bộ stack

```bash
sudo -u deploy bash
cd /opt/ai-wisdom-battle
docker compose -f docker-compose.prod.yml up -d

# Theo dõi khởi động (Neo4j cần ~30 giây)
docker compose -f docker-compose.prod.yml logs -f
```

### 8.3 Seed dữ liệu Neo4j (chỉ lần đầu)

```bash
docker compose -f docker-compose.prod.yml run --rm neo4j-seeder
# Expected output: "Seed complete."
```

### 8.4 Kiểm tra health

```bash
# Backend Spring Boot
curl http://localhost:8080/actuator/health
# {"status":"UP"}

# Python Adaptive Engine
curl http://localhost:8001/health
# {"status":"ok"}

# Website qua Caddy (HTTPS tự động từ sslip.io)
curl -I https://<PUBLIC_IP>.sslip.io
# HTTP/2 200

# Trạng thái tất cả containers
docker compose -f docker-compose.prod.yml ps
```

Mở trình duyệt: `https://<PUBLIC_IP>.sslip.io`

---

## 9. CI/CD tự động sau đó

Sau khi VM đã chạy, thiết lập CI/CD để mỗi push lên `master` tự động deploy.

### 9.1 Tạo SSH key riêng cho GitHub Actions

```bash
# Trên máy local
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy -N ""
```

### 9.2 Thêm public key vào VM

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>

echo "$(cat ~/.ssh/github_deploy.pub)" \
  | sudo tee -a /home/deploy/.ssh/authorized_keys

# Kiểm tra
cat /home/deploy/.ssh/authorized_keys
```

### 9.3 Thêm secrets vào GitHub

**GitHub repo → Settings → Secrets and variables → Actions**

Tab **Secrets** → **New repository secret**:

| Secret | Giá trị |
|---|---|
| `ORACLE_VM_IP` | Public IP của Oracle VM (từ `terraform output public_ip`) |
| `ORACLE_SSH_KEY` | Nội dung file `~/.ssh/github_deploy` (private key) |
| `CLOUDFLARE_API_TOKEN` | CF → My Profile → API Tokens → *Edit Cloudflare Pages* |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare dashboard → bên phải màn hình chính |

Tab **Variables** → **New repository variable**:

| Variable | Giá trị |
|---|---|
| `VITE_API_BASE_URL` | `https://<PUBLIC_IP>.sslip.io/api/v1` |

### 9.4 Kích hoạt

Push lên `master` → `.github/workflows/deploy.yml` chạy tự động:
1. Chạy tests (Java + Python + Frontend)
2. Nếu pass → 2 jobs song song:
   - `deploy-backend`: SSH vào Oracle VM, git pull + rebuild + restart
   - `deploy-frontend`: build React + deploy Cloudflare Pages

---

## 10. Quản lý và cập nhật hạ tầng

### Xem trạng thái hạ tầng hiện tại

```bash
cd infra/oracle
terraform show           # toàn bộ state
terraform output         # chỉ outputs (IP, SSH command)
```

### Cập nhật cấu hình VM (ví dụ tăng RAM)

Sửa `terraform.tfvars`:
```hcl
instance_memory_gb = 24   # không thay đổi gì nếu đang dùng max
```

Áp dụng thay đổi:
```bash
terraform plan   # kiểm tra trước
terraform apply
```

> **Lưu ý**: Thay đổi shape config của VM sẽ tạm dừng instance trong ~1–2 phút.

### Thêm domain thật sau này

1. Trỏ A record của domain về `<PUBLIC_IP>`
2. Cập nhật `.env` trên VM:
   ```bash
   SITE_ADDRESS=awb.example.com
   CORS_ALLOWED_ORIGINS=https://awb.example.com
   ```
3. Restart Caddy:
   ```bash
   sudo -u deploy bash -c "cd /opt/ai-wisdom-battle && docker compose -f docker-compose.prod.yml restart caddy"
   ```
   Caddy tự cấp SSL cert mới cho domain.

---

## 11. Xóa toàn bộ hạ tầng

> **Cảnh báo**: Lệnh này xóa VM và toàn bộ dữ liệu trên VM. Backup trước nếu cần.

```bash
cd infra/oracle
terraform destroy
# Gõ "yes" để xác nhận
```

Terraform xóa theo thứ tự ngược lại: Instance → Subnet → Security List → Route Table → IGW → VCN.

---

## 12. Xử lý sự cố

### `terraform init` lỗi "Failed to install provider"

```bash
# Xóa cache provider và thử lại
rm -rf .terraform .terraform.lock.hcl
terraform init
```

Kiểm tra kết nối internet và version trong `main.tf` (`~> 5.0`).

---

### `terraform apply` lỗi "Out of host capacity"

Oracle Cloud không có ARM VM trống ở Availability Domain đó. Giải pháp:

```bash
# Thử AD khác (index 1 hoặc 2 thay vì 0)
```

Sửa `main.tf` dòng `availability_domain`:

```hcl
# Thay [0] thành [1] hoặc [2]
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
```

Rồi `terraform apply` lại. Có thể thử lúc khác trong ngày — pool ARM thường available hơn vào ban đêm.

---

### `terraform apply` lỗi xác thực OCI

```
Error: 401-NotAuthenticated
```

Kiểm tra:

```bash
# Test OCI credentials thủ công
oci iam region list --auth api_key \
  --tenancy-id <tenancy_ocid> \
  --user-id <user_ocid> \
  --fingerprint <fingerprint> \
  --key-file ~/.oci/oci_api_key.pem

# Nếu lỗi "PEM routines" → private key bị lỗi format
# Tạo lại API key trên OCI Console
```

---

### SSH vào VM thất bại sau khi Terraform xong

Có 2 lý do thường gặp:

**1. cloud-init chưa xong** — chờ thêm 3–5 phút rồi thử lại.

**2. Wrong private key** — đảm bảo dùng đúng private key tương ứng với `ssh_public_key` trong `terraform.tfvars`:

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP> -v
```

---

### Port 80/443 không truy cập được

Oracle Cloud có 2 lớp firewall. Kiểm tra cả hai:

**Lớp 1: OCI Security List** — Terraform đã tạo rules đúng, nhưng kiểm tra lại:

```bash
cd infra/oracle
terraform state show oci_core_security_list.awb_sl | grep -A3 "ingress"
```

**Lớp 2: iptables trong VM** — Oracle Ubuntu có rules mặc định chặn. Xóa chúng:

```bash
ssh -i ~/.ssh/oracle_awb ubuntu@<PUBLIC_IP>
sudo iptables -L INPUT --line-numbers   # xem các rules
sudo iptables -F                        # xóa tất cả
sudo netfilter-persistent save 2>/dev/null || true
sudo ufw status                         # UFW phải ACTIVE với 22,80,443 open
```

---

### `terraform.tfstate` bị mất

File `terraform.tfstate` lưu mapping giữa config và resource thật trên Oracle Cloud. Nếu mất:

```bash
# Import lại instance đã tạo
terraform import oci_core_instance.awb_server <instance-ocid>
```

**Phòng tránh**: commit `terraform.tfstate` vào repo private, hoặc dùng Terraform Cloud/S3 backend để lưu state từ xa:

```hcl
# Ví dụ: lưu state trên Oracle Object Storage
terraform {
  backend "s3" {
    bucket   = "awb-tf-state"
    key      = "oracle/terraform.tfstate"
    region   = "ap-singapore-1"
    endpoint = "https://<namespace>.compat.objectstorage.ap-singapore-1.oraclecloud.com"
    # ...
  }
}
```

---

## Tóm tắt luồng deploy

```
Lần đầu:
  terraform init
  terraform apply
       ↓
  SSH vào VM (sau ~5 phút cloud-init)
  sudo -u deploy nano /opt/ai-wisdom-battle/.env
  sudo -u deploy bash -c "cd /opt/ai-wisdom-battle && docker compose -f docker-compose.prod.yml up -d"
  docker compose -f docker-compose.prod.yml run --rm neo4j-seeder
       ↓
  Website: https://<IP>.sslip.io  ✅

Các lần deploy sau (tự động):
  git push origin master
       ↓
  GitHub Actions chạy tests + SSH deploy
       ↓
  Done ✅
```
