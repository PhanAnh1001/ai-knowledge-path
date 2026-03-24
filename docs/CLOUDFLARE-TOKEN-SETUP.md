# Hướng dẫn tạo Cloudflare API Token

> **[English version](#english) | [日本語版](#japanese)**

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
ssh -i ~/.ssh/lightsail_awb ubuntu@<LIGHTSAIL_IPv6>
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

---

<a name="english"></a>

---

# Creating a Cloudflare API Token (English)

## What is this token used for?

`CLOUDFLARE_API_TOKEN` serves two purposes in this project:

| Purpose | Files | Required permission |
|---|---|---|
| **Caddy DNS-01 TLS challenge** — Caddy automatically obtains a TLS certificate for `api.aiwisdombattle.com` via Let's Encrypt by creating/deleting a `_acme-challenge` TXT record | `Caddyfile`, `docker-compose.prod.yml` | `Zone → DNS → Edit` |
| **Deploy frontend to Cloudflare Pages** — GitHub Actions uses `cloudflare/pages-action@v1` to publish the React app | `.github/workflows/deploy.yml` | `Cloudflare Pages → Edit` (account level) |

A single token is used for both, so it must have **both permissions**.

---

## Step 1 — Log in to Cloudflare Dashboard

Go to [dash.cloudflare.com](https://dash.cloudflare.com) and log in.

## Step 2 — Open API Tokens page

1. Click the **avatar icon** in the top right
2. Select **My Profile**
3. Click the **API Tokens** tab
4. Click **Create Token**

## Step 3 — Create a custom token

Select **Create Custom Token** (do not use a template).

### Token name

```
ai-wisdom-battle-prod
```

### Permissions — add exactly 2 rows

| # | Resource | Permission |
|---|---|---|
| 1 | `Zone` → `DNS` | `Edit` |
| 2 | `Account` → `Cloudflare Pages` | `Edit` |

### Zone Resources

Under the `Zone → DNS → Edit` permission, set **Zone Resources** to:
- **Specific zone** → `aiwisdombattle.com`

### Finalize

1. Click **Continue to summary**
2. Verify the listed permissions match the table above
3. Click **Create Token**
4. **Copy the token immediately** — it is shown only once.

---

## Step 4 — Save the token

**On Lightsail VM** (for Caddy):
```bash
# Edit /opt/ai-wisdom-battle/.env
CLOUDFLARE_API_TOKEN=<your-token>

# Restart Caddy
docker compose -f docker-compose.prod.yml restart caddy
```

**In GitHub Secrets** (for deploy workflow):
- Repo → Settings → Secrets and variables → Actions → New repository secret
- Name: `CLOUDFLARE_API_TOKEN`, Value: `<your-token>`

---

## Step 5 — Verify

```bash
# Check Caddy obtained a TLS certificate
docker logs awb-caddy --tail 50 | grep -E "certificate|tls"

# Test the HTTPS endpoint
curl -sf https://api.aiwisdombattle.com/health
```

For Cloudflare Pages: trigger a deploy from GitHub Actions and confirm the `Deploy to Cloudflare Pages` step succeeds.

---

<a name="japanese"></a>

---

# Cloudflare APIトークンの作成手順 (Japanese)

## このトークンの用途

`CLOUDFLARE_API_TOKEN`はこのプロジェクトで**2つの目的**に使用されます。

| 用途 | 関連ファイル | 必要な権限 |
|---|---|---|
| **Caddy DNS-01 TLSチャレンジ** — CaddyがLet's Encrypt経由で`api.aiwisdombattle.com`のTLS証明書を自動取得する際、CloudflareのDNSに`_acme-challenge` TXTレコードを作成・削除する | `Caddyfile`、`docker-compose.prod.yml` | `Zone → DNS → Edit` |
| **Cloudflare Pagesへのフロントエンドデプロイ** — GitHub Actionsが`cloudflare/pages-action@v1`を使用してReactアプリを公開する | `.github/workflows/deploy.yml` | `Cloudflare Pages → Edit`（アカウントレベル） |

1つのトークンで両方の用途を賄うため、**両方の権限が必要**です。

---

## 手順1 — Cloudflare Dashboardにログイン

[dash.cloudflare.com](https://dash.cloudflare.com)にアクセスしてログインします。

## 手順2 — APIトークンページを開く

1. 右上の**アバターアイコン**をクリック
2. **My Profile**を選択
3. **API Tokens**タブをクリック
4. **Create Token**ボタンをクリック

## 手順3 — カスタムトークンを作成

**Create Custom Token**を選択（テンプレートは使用しない）。

### トークン名

```
ai-wisdom-battle-prod
```

### 権限の追加 — 以下の2行を正確に設定

| # | リソース | 権限 |
|---|---|---|
| 1 | `Zone` → `DNS` | `Edit` |
| 2 | `Account` → `Cloudflare Pages` | `Edit` |

### Zoneリソースの絞り込み

`Zone → DNS → Edit`の権限追加後、**Zone Resources**セクションで：
- **Specific zone** → `aiwisdombattle.com`を選択

### 完了

1. **Continue to summary**をクリック
2. 権限リストが上記の表と一致していることを確認
3. **Create Token**をクリック
4. **トークンをすぐにコピーする** — 一度しか表示されません。

---

## 手順4 — トークンの保存

**LightsailのVM上**（Caddy用）:
```bash
# /opt/ai-wisdom-battle/.env を編集
CLOUDFLARE_API_TOKEN=<取得したトークン>

# Caddyを再起動
docker compose -f docker-compose.prod.yml restart caddy
```

**GitHub Secrets**（デプロイワークフロー用）:
- リポジトリ → Settings → Secrets and variables → Actions → New repository secret
- 名前: `CLOUDFLARE_API_TOKEN`、値: `<取得したトークン>`

---

## 手順5 — 動作確認

```bash
# CaddyがTLS証明書を取得したか確認
docker logs awb-caddy --tail 50 | grep -E "certificate|tls"

# HTTPSエンドポイントのテスト
curl -sf https://api.aiwisdombattle.com/health
```

Cloudflare Pagesのデプロイ確認はGitHub Actionsのワークフロータブで`Deploy to Cloudflare Pages`ステップの成功を確認してください。

---

## よくあるエラーと対処法

| エラー | 原因 | 対処法 |
|---|---|---|
| `dns: cloudflare: failed to find zone` | `Zone:DNS:Edit`権限がないか、ゾーンが間違っている | トークンのゾーンが`aiwisdombattle.com`であることを確認 |
| `Error 10000: Authentication error` | トークンが無効または期限切れ | 新しいトークンを作成し、`.env`とGitHub Secretを更新 |
| Pages: `9109 Account not found` | `CLOUDFLARE_ACCOUNT_ID`が間違っている | CloudflareダッシュボードのWorkers & Pagesページ右サイドバーでAccount IDを確認 |
