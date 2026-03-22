# Hướng dẫn lấy OCI Secrets và cấu hình GitHub

Tài liệu này hướng dẫn từng bước lấy thông tin từ Oracle Cloud, tạo SSH key, rồi lưu tất cả vào GitHub Secrets để workflow Terraform có thể chạy.

---

## Tổng quan — 7 secrets cần tạo

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

## Phần 1 — Lấy thông tin từ OCI Console

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

## Phần 2 — Tạo SSH Key

SSH key dùng để SSH vào VM sau khi Terraform tạo xong. Tạo một lần, dùng mãi.

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

## Phần 3 — Lưu vào GitHub Secrets

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

## Phần 4 — Kiểm tra và chạy

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
