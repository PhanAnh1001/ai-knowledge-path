# Hướng dẫn tạo Cloudflare API Token

---

## Tổng quan — Token dùng để làm gì?

`CLOUDFLARE_API_TOKEN` được dùng cho **hai mục đích khác nhau** trong dự án:

| Mục đích | File liên quan | Quyền cần thiết |
|---|---|---|
| **Caddy DNS-01 TLS challenge** — Caddy tự động xin TLS cert cho `api.aiwisdombattle.com` qua Let's Encrypt, cần tạo/xoá TXT record `_acme-challenge` trên DNS Cloudflare | `Caddyfile`, `docker-compose.prod.yml` | `Zone → DNS → Edit` |
| **Deploy frontend lên Cloudflare Pages** — GitHub Actions dùng `cloudflare/pages-action@v1` để publish React app | `.github/workflows/deploy.yml` | `Cloudflare Pages → Edit` (account level) |

Vì một token duy nhất phục vụ cả hai, token phải có **đủ cả hai quyền** trên.

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
Token name: ai-wisdom-battle-prod
```

### 3.2 Thêm quyền (Permissions)

Nhấn **Add permissions** và thêm lần lượt **2 dòng** sau:

| # | Resource | Quyền |
|---|---|---|
| 1 | `Zone` → `DNS` | `Edit` |
| 2 | `Account` → `Cloudflare Pages` | `Edit` |

> **Cách thao tác từng dòng:**
> - Dropdown đầu tiên: chọn `Zone` hoặc `Account`
> - Dropdown thứ hai: chọn resource cụ thể (`DNS` hoặc `Cloudflare Pages`)
> - Dropdown thứ ba: chọn `Edit`

### 3.3 Thu hẹp phạm vi Zone (Zone Resources)

Sau khi thêm quyền `Zone → DNS → Edit`, mục **Zone Resources** xuất hiện bên dưới:

- Chọn **Specific zone**
- Chọn zone: `aiwisdombattle.com`

> Không chọn "All zones" để tuân thủ nguyên tắc least privilege — token chỉ có quyền sửa DNS của domain này.

### 3.4 Giới hạn Client IP (tuỳ chọn nhưng khuyến nghị)

Nếu bạn biết IP tĩnh của Lightsail VM, thêm vào mục **Client IP Address Filtering** để tăng bảo mật.

### 3.5 Đặt thời hạn (tuỳ chọn)

Có thể để trống (no expiration) hoặc đặt 1 năm.

### 3.6 Hoàn tất

1. Nhấn **Continue to summary**
2. Kiểm tra lại danh sách quyền:
   ```
   Zone - DNS - Edit - aiwisdombattle.com
   Account - Cloudflare Pages - Edit - <tên account của bạn>
   ```
3. Nhấn **Create Token**
4. **Copy token ngay lập tức** — Cloudflare chỉ hiển thị một lần duy nhất.

Token có dạng:
```
yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Bước 4 — Lưu token vào các nơi cần thiết

### 4.1 File `.env` trên Lightsail VM (cho Caddy)

SSH vào VM và sửa file `.env`:

```bash
ssh -i ~/.ssh/lightsail_awb ubuntu@<LIGHTSAIL_IP>
cd /opt/ai-wisdom-battle
nano .env
```

Tìm dòng và thay `change_me_cloudflare_token` bằng token vừa tạo:

```env
CLOUDFLARE_API_TOKEN=yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Restart Caddy để nạp token mới:

```bash
docker compose -f docker-compose.prod.yml restart caddy
```

### 4.2 GitHub Secret (cho deploy workflow)

1. Vào GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Nhấn **New repository secret**
3. Điền:
   ```
   Name:   CLOUDFLARE_API_TOKEN
   Secret: yJFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. Nhấn **Add secret**

---

## Bước 5 — Kiểm tra hoạt động

### Kiểm tra Caddy DNS-01

```bash
# Xem log Caddy trên VM
docker logs awb-caddy --tail 50

# Nếu thành công, log sẽ có dòng:
# "certificate obtained successfully"
# hoặc "serving certificate" cho domain api.aiwisdombattle.com

# Kiểm tra cert hiện tại
curl -v https://api.aiwisdombattle.com/health 2>&1 | grep -E "subject:|issuer:|expire"
```

### Kiểm tra Cloudflare Pages deploy

1. Vào GitHub repo → tab **Actions** → chọn workflow **Deploy**
2. Trigger thủ công hoặc chờ CI pass
3. Bước `Deploy to Cloudflare Pages` phải hiển thị `Deployment complete`

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `dns: cloudflare: failed to find zone` | Token không có quyền `Zone:DNS:Edit` hoặc sai zone | Kiểm tra zone trong token đúng là `aiwisdombattle.com` |
| `Error 10000: Authentication error` | Token không hợp lệ hoặc đã hết hạn | Tạo token mới, cập nhật vào `.env` và GitHub Secret |
| `Error 1000: DNS points to prohibited IP` | Cloudflare chặn do IP trong cert không khớp | Kiểm tra DNS record `api.aiwisdombattle.com` trỏ đúng IP Lightsail |
| Caddy log: `permission denied` | Token thiếu quyền `DNS:Edit` | Thêm quyền `Zone → DNS → Edit` vào token |
| Pages deploy: `10000 Authentication error` | Token thiếu quyền `Cloudflare Pages:Edit` | Thêm quyền `Account → Cloudflare Pages → Edit` vào token |
| Pages deploy: `9109 Account not found` | `CLOUDFLARE_ACCOUNT_ID` sai | Kiểm tra Account ID trong **Cloudflare Dashboard → Workers & Pages → Overview** (sidebar phải) |

---

## Lưu ý bảo mật

- **Không commit token vào git.** File `.env` đã có trong `.gitignore`.
- Rotate token (tạo mới, xoá cũ) mỗi năm hoặc khi nghi ngờ bị lộ.
- Nếu token bị lộ: vào **Cloudflare → My Profile → API Tokens** → nhấn **Roll** hoặc **Delete** token cũ ngay lập tức.
