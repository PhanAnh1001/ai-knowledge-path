# Hướng dẫn tạo Cloudflare API Token

---

## Tổng quan — Token dùng để làm gì?

`CLOUDFLARE_API_TOKEN` hiện được dùng cho **một mục đích chính**:

| Mục đích | File liên quan | Quyền cần thiết |
|---|---|---|
| **Deploy frontend lên Cloudflare Pages** — GitHub Actions dùng `cloudflare/pages-action@v1` để publish React app | `.github/workflows/deploy.yml` | `Account → Cloudflare Pages → Edit` |

**Nếu bạn có custom domain và dùng Cloudflare proxy**, token cần thêm quyền thứ hai:

| Mục đích | File liên quan | Quyền cần thiết |
|---|---|---|
| **Caddy DNS-01 TLS challenge** — Caddy tự động xin TLS cert qua Let's Encrypt, cần tạo/xoá TXT record `_acme-challenge` trên DNS Cloudflare | `Caddyfile` | `Zone → DNS → Edit` trên zone của bạn |

> **Không có custom domain (dùng `sslip.io`)?** Chỉ cần `Account → Cloudflare Pages → Edit`. Caddy sẽ lấy cert qua HTTP-01 tự động — không cần DNS access.

---

## Bước 1 — Đăng nhập Cloudflare Dashboard

Truy cập [dash.cloudflare.com](https://dash.cloudflare.com) và đăng nhập.

---

## Bước 2 — Mở trang tạo API Token

1. Nhấn vào **icon avatar** góc trên phải
2. Chọn **My Profile**
3. Chọn tab **API Tokens** (thanh ngang)
4. Nhấn nút **Create Token**

---

## Bước 3 — Tạo token với quyền chính xác

Trên trang "Create API Token", chọn **Create Custom Token** (không dùng template).

### 3.1 Đặt tên token

```
Token name: ai-knowledge-path-prod
```

### 3.2 Thêm quyền (Permissions)

**Trường hợp A — Không có custom domain (sslip.io):** chỉ cần **1 dòng**:

| # | Resource | Quyền |
|---|---|---|
| 1 | `Account` → `Cloudflare Pages` | `Edit` |

**Trường hợp B — Có custom domain + Cloudflare proxy:** thêm **2 dòng**:

| # | Resource | Quyền |
|---|---|---|
| 1 | `Account` → `Cloudflare Pages` | `Edit` |
| 2 | `Zone` → `DNS` | `Edit` |

> **Cách thao tác từng dòng:**
> - Dropdown đầu tiên: chọn `Zone` hoặc `Account`
> - Dropdown thứ hai: chọn resource cụ thể (`DNS` hoặc `Cloudflare Pages`)
> - Dropdown thứ ba: chọn `Edit`

### 3.3 Thu hẹp phạm vi Zone (Zone Resources) — chỉ khi có Trường hợp B

Sau khi thêm quyền `Zone → DNS → Edit`, mục **Zone Resources** xuất hiện bên dưới:

- Chọn **Specific zone**
- Chọn zone của bạn (ví dụ: `example.com`)

> Không chọn "All zones" — token chỉ cần quyền sửa DNS của domain này (least privilege).

### 3.4 Giới hạn Client IP (tuỳ chọn nhưng khuyến nghị)

Nếu bạn biết IP tĩnh của Lightsail VM, thêm vào mục **Client IP Address Filtering** để tăng bảo mật.

### 3.5 Đặt thời hạn (tuỳ chọn)

Có thể để trống (no expiration) hoặc đặt 1 năm.

### 3.6 Hoàn tất

1. Nhấn **Continue to summary**
2. Kiểm tra lại danh sách quyền:

   Trường hợp A (không có custom domain):
   ```
   Account - Cloudflare Pages - Edit - <tên account của bạn>
   ```
   Trường hợp B (có custom domain + Cloudflare proxy):
   ```
   Account - Cloudflare Pages - Edit - <tên account của bạn>
   Zone - DNS - Edit - example.com
   ```
3. Nhấn **Create Token**
4. **Copy token ngay lập tức** — Cloudflare chỉ hiển thị một lần duy nhất.

Token có dạng:
```
yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Bước 4 — Lưu token vào GitHub Secret

Deploy workflow tự động inject token vào `.env` trên server — **không cần SSH thủ công**.

### 4.1 Tạo GitHub Secret

```bash
gh secret set CLOUDFLARE_API_TOKEN --body "yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Hoặc qua GitHub UI:
1. Vào GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Nhấn **New repository secret**
3. Điền `Name: CLOUDFLARE_API_TOKEN`, paste token → **Add secret**

### 4.2 Token được dùng ở đâu

| Nơi dùng | Khi nào |
|---|---|
| `deploy.yml` → `cloudflare/pages-action@v1` | Mỗi lần deploy frontend lên Cloudflare Pages |
| `.env` trên Lightsail → Caddy | Chỉ khi dùng DNS-01 challenge (Trường hợp B) |

> **Trường hợp A (sslip.io):** Token được write vào `.env` nhưng Caddy không đọc nó (không có `tls { dns cloudflare }` trong Caddyfile). Không gây hại.

---

## Bước 5 — Kiểm tra hoạt động

### Kiểm tra Caddy TLS cert

```bash
# SSH vào server, xem log Caddy
ssh -i ~/.ssh/awb-lightsail ubuntu@<LIGHTSAIL_IP>
docker logs awb-caddy --tail 50

# Nếu thành công:
# HTTP-01 → log có "certificate obtained successfully"
# DNS-01  → log có "served certificate" kèm tên domain

# Kiểm tra cert từ ngoài (thay <API_DOMAIN> bằng giá trị thực)
curl -v https://<API_DOMAIN>/health 2>&1 | grep -E "subject:|issuer:|expire"
```

### Kiểm tra Cloudflare Pages deploy

1. Vào GitHub repo → tab **Actions** → chọn workflow **Deploy**
2. Trigger thủ công hoặc chờ CI pass trên master
3. Bước `Deploy to Cloudflare Pages` phải hiển thị `Deployment complete`
4. Truy cập `https://ai-knowledge-path.pages.dev` → app load bình thường

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| Pages deploy: `10000 Authentication error` | Token thiếu quyền `Cloudflare Pages:Edit` hoặc token hết hạn | Thêm quyền `Account → Cloudflare Pages → Edit` vào token; hoặc tạo token mới |
| Pages deploy: `9109 Account not found` | `CLOUDFLARE_ACCOUNT_ID` sai | Kiểm tra Account ID trong **Cloudflare Dashboard → Workers & Pages → Overview** (sidebar phải) |
| Caddy log: `certificate obtain error` (HTTP-01) | Port 80 bị chặn, firewall Lightsail chưa mở | Kiểm tra Lightsail firewall: TCP 80 phải open |
| `dns: cloudflare: failed to find zone` | Đang dùng DNS-01 nhưng token thiếu `Zone:DNS:Edit` hoặc sai zone | Chỉ gặp ở Trường hợp B — thêm quyền và chọn đúng zone |
| `Error 10000: Authentication error` (Caddy) | Token không hợp lệ hoặc hết hạn | Tạo token mới, cập nhật GitHub Secret rồi deploy lại |

---

## Lưu ý bảo mật

- **Không commit token vào git.** File `.env` đã có trong `.gitignore`.
- Rotate token (tạo mới, xoá cũ) mỗi năm hoặc khi nghi ngờ bị lộ.
- Nếu token bị lộ: vào **Cloudflare → My Profile → API Tokens** → nhấn **Roll** hoặc **Delete** token cũ ngay lập tức.
