# Hướng dẫn cấu hình GitHub Secrets & Variables

Tài liệu này hướng dẫn cấu hình tất cả Secrets và Variables cần thiết cho CI/CD pipeline.

> **Stack hiện tại (Active):** AWS Lightsail + Cloudflare — xem Phần 0 bên dưới.
> **Stack cũ (Legacy):** Oracle Cloud — xem Phần 1–4.

---

## Phần 0 — Secrets & Variables cho AWS Lightsail (Active)

### 0.1 Tổng quan — 9 secrets + 3 variables

| Name | Loại | Mô tả | Dùng cho |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | Secret | AWS Access Key ID | Terraform tạo Lightsail VM |
| `AWS_SECRET_ACCESS_KEY` | Secret | AWS Secret Access Key | Terraform tạo Lightsail VM |
| `SSH_PUBLIC_KEY` | Secret | SSH public key RSA 4096-bit | Terraform upload key pair |
| `LIGHTSAIL_HOST` | Secret | Public IPv4 Lightsail instance | Deploy workflow SSH |
| `LIGHTSAIL_SSH_KEY` | Secret | SSH private key RSA 4096-bit | Deploy workflow SSH |
| `CLOUDFLARE_API_TOKEN` | Secret | CF token — quyền tối thiểu: `Account → Cloudflare Pages → Edit` | Frontend deploy (Pages) |
| `CLOUDFLARE_ACCOUNT_ID` | Secret | Cloudflare Account ID | Frontend deploy (Pages) |
| `POSTGRES_PASSWORD` | Secret | Mật khẩu PostgreSQL mạnh | Deploy → .env injection |
| `JWT_SECRET` | Secret | Khoá JWT (≥ 32 ký tự) | Deploy → .env injection |
| `API_DOMAIN` | Variable | Domain/subdomain cho backend API | Deploy → .env + Caddyfile |
| `VITE_API_BASE_URL` | Variable | API base URL cho frontend build | CI frontend build |
| `CORS_ALLOWED_ORIGINS` | Variable | Allowed origins cho CORS | Deploy → .env injection |

> **`CLOUDFLARE_API_TOKEN` — quyền cần thiết phụ thuộc vào setup:**
> - **Không có custom domain** (dùng `sslip.io`): chỉ cần `Account → Cloudflare Pages → Edit`
> - **Có custom domain + Cloudflare proxy**: cần thêm `Zone → DNS → Edit` (cho Caddy DNS-01 TLS challenge)
>
> Xem chi tiết: [CLOUDFLARE-TOKEN-SETUP.md](CLOUDFLARE-TOKEN-SETUP.md)

### 0.2 Tạo nhanh bằng GitHub CLI

```bash
gh auth login

# === Terraform (tạo trước bước Terraform apply) ===
gh secret set AWS_ACCESS_KEY_ID      --body "<access-key-id>"
gh secret set AWS_SECRET_ACCESS_KEY  --body "<secret-access-key>"
gh secret set SSH_PUBLIC_KEY         < ~/.ssh/awb-lightsail.pub

# === Deploy backend (tạo sau khi có public IP) ===
gh secret set LIGHTSAIL_HOST         --body "<IP-từ-terraform-output>"
gh secret set LIGHTSAIL_SSH_KEY      < ~/.ssh/awb-lightsail
gh secret set CLOUDFLARE_API_TOKEN   --body "<token-từ-cloudflare>"
gh secret set CLOUDFLARE_ACCOUNT_ID  --body "<account-id>"
gh secret set POSTGRES_PASSWORD      --body "$(openssl rand -base64 24)"
gh secret set JWT_SECRET             --body "$(openssl rand -base64 32)"

# === Variables (thay <IP> bằng public IPv4 từ Terraform output) ===
# Nếu không có custom domain, dùng sslip.io:
IP="<IP-từ-terraform-output>"
gh variable set API_DOMAIN           --body "${IP}.sslip.io"
gh variable set VITE_API_BASE_URL    --body "https://${IP}.sslip.io/api/v1"
gh variable set CORS_ALLOWED_ORIGINS --body "https://ai-wisdom-battle.pages.dev"

# Nếu có custom domain (ví dụ example.com):
# gh variable set API_DOMAIN           --body "api.example.com"
# gh variable set VITE_API_BASE_URL    --body "https://api.example.com/api/v1"
# gh variable set CORS_ALLOWED_ORIGINS --body "https://example.com,https://ai-wisdom-battle.pages.dev"
```

### 0.3 Cách lấy từng secret

| Secret | Cách lấy |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | AWS IAM Console → Users → Security credentials → Create access key |
| `SSH_PUBLIC_KEY` / `LIGHTSAIL_SSH_KEY` | `ssh-keygen -t rsa -b 4096 -f ~/.ssh/awb-lightsail` (xem [DEPLOY-LIGHTSAIL-DAY5.md](DEPLOY-LIGHTSAIL-DAY5.md) bước 1.1) |
| `LIGHTSAIL_HOST` | Terraform output sau khi apply (xem bước 1.4 trong DEPLOY-LIGHTSAIL-DAY5.md) |
| `CLOUDFLARE_API_TOKEN` | Xem hướng dẫn chi tiết tại [CLOUDFLARE-TOKEN-SETUP.md](CLOUDFLARE-TOKEN-SETUP.md) |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Dashboard → Workers & Pages → sidebar phải |
| `POSTGRES_PASSWORD` | Tạo random: `openssl rand -base64 24` |
| `JWT_SECRET` | Tạo random: `openssl rand -base64 32` |

### 0.4 Lưu ý bảo mật

- Deploy workflow tự động inject `POSTGRES_PASSWORD`, `JWT_SECRET`, `CLOUDFLARE_API_TOKEN`, `API_DOMAIN` vào `.env` trên server — không cần SSH thủ công
- GitHub Actions auto-redact tất cả secret values trong log (hiển thị `***`)
- File `.env` trên server có quyền `600` — chỉ owner đọc được
- Rotate secrets bằng cách update GitHub Secret rồi trigger deploy lại
- `API_DOMAIN`, `VITE_API_BASE_URL`, `CORS_ALLOWED_ORIGINS` là **Variables** (không phải Secret) — không nhạy cảm, có thể xem trong GitHub UI

---

## Phần 1 (Legacy — Oracle Cloud) — Lấy thông tin từ OCI Console

> **Lưu ý:** Phần 1–4 chỉ dùng cho Oracle Cloud (legacy). Stack hiện tại dùng AWS Lightsail (xem Phần 0).

---

## Tổng quan OCI — 7 secrets cần tạo

| Secret | Mô tả ngắn |
|---|---|
| `OCI_TENANCY_OCID` | ID tài khoản OCI của bạn |
| `OCI_USER_OCID` | ID user đang đăng nhập |
| `OCI_FINGERPRINT` | Dấu vân tay của API Key |
| `OCI_API_PRIVATE_KEY` | Nội dung file private key PEM |
| `OCI_REGION` | Region Oracle Cloud |
| `OCI_COMPARTMENT_OCID` | ID compartment (thường = tenancy) |
| `SSH_PUBLIC_KEY` | SSH public key để vào VM |

---

### 1.1 Đăng nhập OCI Console

Truy cập [cloud.oracle.com](https://cloud.oracle.com) → đăng nhập.

---

### 1.2 Lấy `OCI_TENANCY_OCID`

1. Nhấn vào **icon avatar** góc trên phải
2. Chọn **Tenancy: \<tên của bạn\>**
3. Trang mở ra, nhìn mục **OCID** → nhấn **Copy**

```
ocid1.tenancy.oc1..aaaaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> Dùng giá trị này cho cả `OCI_COMPARTMENT_OCID` (root compartment).

---

### 1.3 Lấy `OCI_USER_OCID`

1. Nhấn **icon avatar** góc trên phải
2. Chọn **My profile** (hoặc **User settings**)
3. Mục **OCID** → nhấn **Copy**

```
ocid1.user.oc1..aaaaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 1.4 Lấy `OCI_REGION`

Nhìn vào thanh URL của OCI Console, ví dụ:

```
https://cloud.oracle.com/?region=ap-singapore-1
```

Hoặc xem menu dropdown region ở góc trên phải. Các region phổ biến:

| Region | Mã |
|---|---|
| Singapore | `ap-singapore-1` |
| Tokyo | `ap-tokyo-1` |
| Sydney | `ap-sydney-1` |
| Ashburn (US) | `us-ashburn-1` |
| Frankfurt (EU) | `eu-frankfurt-1` |

---

### 1.5 Tạo API Key → lấy `OCI_FINGERPRINT` và `OCI_API_PRIVATE_KEY`

1. Vào **My profile → API keys** (menu bên trái, phần *Resources*)
2. Nhấn **Add API key**
3. Chọn **Generate API key pair**
4. Nhấn **Download private key** → lưu file `*.pem` về máy (chỉ tải được 1 lần)
5. Nhấn **Add**
6. Hộp thoại xác nhận hiện ra, nhìn dòng `fingerprint:` → copy giá trị dạng:

```
a1:b2:c3:d4:e5:f6:00:11:22:33:44:55:66:77:88:99
```

**Lấy nội dung private key:**

```bash
# Mở file vừa tải về (tên thường là oracle_xxxxx.pem hoặc oci_api_key.pem)
cat ~/Downloads/oracle_xxxxxxxx.pem
```

Nội dung trông như thế này — copy **toàn bộ** bao gồm cả dòng `-----BEGIN-----` và `-----END-----`:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
...
-----END RSA PRIVATE KEY-----
```

---

## Phần 2 (Legacy — Oracle Cloud) — Tạo SSH Key

SSH key dùng để SSH vào VM Oracle Cloud sau khi Terraform tạo xong. Tạo một lần, dùng mãi.

### Trên máy tính (Linux / macOS / WSL)

```bash
# Tạo key pair
ssh-keygen -t ed25519 -C "oracle-awb" -f ~/.ssh/oracle_awb

# Nhấn Enter 2 lần (không cần passphrase)

# Xem public key — copy toàn bộ dòng này
cat ~/.ssh/oracle_awb.pub
```

Kết quả dạng:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx oracle-awb
```

> **Lưu private key an toàn:** `~/.ssh/oracle_awb` dùng để SSH vào VM sau này:
> ```bash
> ssh -i ~/.ssh/oracle_awb ubuntu@<VM_PUBLIC_IP>
> ```

### Trên OCI Cloud Shell (không có máy tính)

Vào OCI Console → nhấn icon **Cloud Shell** (terminal) góc trên phải:

> **Lưu ý:** OCI Cloud Shell chạy ở chế độ FIPS 140-2, không hỗ trợ ED25519. Dùng RSA 4096 thay thế:

```bash
ssh-keygen -t rsa -b 4096 -C "oracle-awb" -f ~/.ssh/oracle_awb

# Nhấn Enter 2 lần (không cần passphrase)

cat ~/.ssh/oracle_awb.pub
```

Kết quả dạng:

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx oracle-awb
```

---

## Phần 3 (Legacy — Oracle Cloud) — Lưu vào GitHub Secrets

### 3.1 Mở trang Secrets

1. Vào **GitHub repo** của bạn
2. Nhấn **Settings** (tab trên cùng)
3. Sidebar trái → **Secrets and variables** → **Actions**
4. Nhấn **New repository secret**

### 3.2 Thêm lần lượt 7 secrets

Với mỗi secret: nhập **Name** → paste **Secret** → nhấn **Add secret**.

---

#### `OCI_TENANCY_OCID`
```
Name:   OCI_TENANCY_OCID
Secret: ocid1.tenancy.oc1..aaaaaaaaxxx...   ← lấy ở bước 1.2
```

---

#### `OCI_USER_OCID`
```
Name:   OCI_USER_OCID
Secret: ocid1.user.oc1..aaaaaaaaxxx...   ← lấy ở bước 1.3
```

---

#### `OCI_FINGERPRINT`
```
Name:   OCI_FINGERPRINT
Secret: a1:b2:c3:d4:e5:f6:...   ← lấy ở bước 1.5
```

---

#### `OCI_API_PRIVATE_KEY`
```
Name:   OCI_API_PRIVATE_KEY
Secret: ← paste TOÀN BỘ nội dung file .pem, bao gồm dòng BEGIN và END
```

> Ví dụ nội dung cần paste:
> ```
> -----BEGIN RSA PRIVATE KEY-----
> MIIEowIBAAKCAQEAxxx...
> ...nhiều dòng...
> -----END RSA PRIVATE KEY-----
> ```

---

#### `OCI_REGION`
```
Name:   OCI_REGION
Secret: ap-singapore-1   ← hoặc region của bạn (xem bước 1.4)
```

---

#### `OCI_COMPARTMENT_OCID`
```
Name:   OCI_COMPARTMENT_OCID
Secret: ocid1.tenancy.oc1..aaaaaaaaxxx...   ← giống OCI_TENANCY_OCID (root compartment)
```

---

#### `SSH_PUBLIC_KEY`
```
Name:   SSH_PUBLIC_KEY
Secret: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...   ← nội dung file oracle_awb.pub (bước 2)
```

---

## Phần 4 (Legacy — Oracle Cloud) — Kiểm tra và chạy

### 4.1 Xác nhận đủ 7 secrets

Vào **Settings → Secrets and variables → Actions**, kiểm tra danh sách:

- [ ] `OCI_TENANCY_OCID`
- [ ] `OCI_USER_OCID`
- [ ] `OCI_FINGERPRINT`
- [ ] `OCI_API_PRIVATE_KEY`
- [ ] `OCI_REGION`
- [ ] `OCI_COMPARTMENT_OCID`
- [ ] `SSH_PUBLIC_KEY`

### 4.2 Chạy Plan để kiểm tra credentials

1. Tab **Actions** → **Terraform (Oracle Cloud)** → **Run workflow**
2. Chọn action: **`plan`**
3. Nhấn **Run workflow**
4. Đợi ~1 phút → xem log

**Thành công** nếu bước `Terraform Plan` hiển thị danh sách resources sẽ tạo (không có lỗi `authentication` hay `permission denied`).

### 4.3 Apply — tạo hạ tầng thật

Sau khi `plan` thành công:

1. Chạy lại workflow, chọn action: **`apply`**
2. Đợi ~5-10 phút
3. Xem bước **Terraform Output** để lấy Public IP:

```
public_ip    = "140.238.x.x"
ssh_command  = "ssh -i ~/.ssh/oracle_awb ubuntu@140.238.x.x"
site_address = "140.238.x.x.sslip.io"
```

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `authentication failed` | Fingerprint hoặc private key sai | Kiểm tra lại `OCI_FINGERPRINT` và `OCI_API_PRIVATE_KEY` |
| `private key is malformed` | Paste thiếu dòng BEGIN/END hoặc thừa khoảng trắng | Paste lại toàn bộ nội dung file `.pem` |
| `user not authorized` | User không có quyền trên compartment | Dùng `OCI_COMPARTMENT_OCID` = `OCI_TENANCY_OCID` |
| `out of host capacity` | OCI hết Always Free capacity | Thử region khác hoặc thử lại sau |
| `context deadline exceeded` | Timeout mạng | Chạy lại workflow |
| `ED25519 keys are not allowed in FIPS mode` | OCI Cloud Shell chạy FIPS 140-2, không hỗ trợ ED25519 | Dùng `ssh-keygen -t rsa -b 4096` thay cho `-t ed25519` |
