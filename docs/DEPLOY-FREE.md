# Deploy Production Miễn Phí — AI Wisdom Battle

`docker-compose.yml` chỉ dùng ở **local dev**. Production deploy từng service riêng.

## Kiến trúc production

```
Internet
   │
   ├── Cloudflare Pages ──── React Frontend (static, CDN toàn cầu)
   │        │
   │   HTTPS /api/v1  ──→  Fly.io awb-backend (Spring Boot :8080)
   │                               │
   │                               ├── Neon          (PostgreSQL)
   │                               ├── Neo4j Aura    (Graph DB)
   │                               ├── Upstash       (Redis, TLS)
   │                               └── awb-engine    (Python FastAPI :8001)
   │                                      (Fly.io, cùng org)
```

## Dịch vụ miễn phí cần đăng ký

| Service | Dùng cho | Giới hạn free | Đăng ký |
|---|---|---|---|
| **Fly.io** | Spring Boot + Python | 3 VM × 256–512MB | fly.io |
| **Neon** | PostgreSQL | 512 MB, 1 project | neon.tech |
| **Neo4j Aura** | Graph DB | 200K nodes | console.neo4j.io |
| **Upstash** | Redis (TLS) | 10K cmd/ngày | upstash.com |
| **Cloudflare Pages** | React frontend | Không giới hạn | pages.cloudflare.com |

---

## Fly.io — CLI hay Web UI?

| Thao tác | CLI bắt buộc | Web UI thay được |
|---|---|---|
| Tạo app lần đầu | ✅ `flyctl launch` (chỉ 1 lần) | ❌ |
| Set / sửa secrets | `flyctl secrets set` | ✅ dashboard.fly.io → app → **Secrets** |
| Xem logs | `flyctl logs` | ✅ app → **Monitoring → Logs** |
| Scale memory | `flyctl scale memory` | ✅ app → **Machines → Edit** |
| Deploy code mới | `flyctl deploy` | ❌ nhưng **GitHub Actions tự làm** |

**Tóm lại**: chỉ cần gõ CLI **2 lần duy nhất** khi tạo app lần đầu. Sau đó mọi thứ qua web UI hoặc CI/CD tự động.

---

## Bước 1 — Cài flyctl & tạo apps (CLI, chỉ làm 1 lần)

```bash
curl -L https://fly.io/install.sh | sh
flyctl auth signup   # hoặc: flyctl auth login
```

```bash
# Tạo app backend — từ thư mục gốc project
flyctl launch --no-deploy --name awb-backend
# Hỏi "overwrite fly.toml?" → No   |   Region: sin (Singapore) hoặc nrt (Tokyo)

# Tạo app engine — từ thư mục adaptive-engine/
cd adaptive-engine
flyctl launch --no-deploy --name awb-engine
# Hỏi "overwrite fly.toml?" → No
cd ..
```

---

## Bước 2 — Tạo databases

### PostgreSQL — Neon

1. Đăng ký [neon.tech](https://neon.tech) → **New Project**
2. Lấy Connection String (JDBC format):
   ```
   jdbc:postgresql://ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
3. Lưu: `DB_URL`, `DB_USER`, `DB_PASSWORD`

### Neo4j — Aura Free

1. Đăng ký [console.neo4j.io](https://console.neo4j.io) → **Create Free Instance**
2. **Lưu ngay** password (chỉ hiện 1 lần)
3. Bolt URI dạng: `neo4j+s://xxxxxxxx.databases.neo4j.io`
4. Lưu: `NEO4J_URI`, `NEO4J_USER=neo4j`, `NEO4J_PASSWORD`

### Redis — Upstash

1. Đăng ký [upstash.com](https://upstash.com) → **Create Database** → chọn region gần nhất
2. Lấy từ tab **Details**:
   - **Endpoint** (host): `xxx.upstash.io`
   - **Port**: `6379`
   - **Password**: mục *Redis Password*
3. Lưu: `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
4. `REDIS_SSL=true` đã set sẵn trong `fly.toml`

---

## Bước 3 — Set secrets cho awb-backend

### Cách A — Web UI (khuyến nghị, không cần CLI)

1. Vào [fly.io/apps/awb-backend/secrets](https://fly.io/apps/awb-backend/secrets)
2. Nhấn **Add secret**, nhập từng cặp key/value:

| Key | Value |
|---|---|
| `DB_URL` | `jdbc:postgresql://ep-xxx.../neondb?sslmode=require` |
| `DB_USER` | user Neon của bạn |
| `DB_PASSWORD` | password Neon |
| `NEO4J_URI` | `neo4j+s://xxxxxxxx.databases.neo4j.io` |
| `NEO4J_USER` | `neo4j` |
| `NEO4J_PASSWORD` | password Aura |
| `REDIS_HOST` | `xxx.upstash.io` |
| `REDIS_PORT` | `6379` |
| `REDIS_PASSWORD` | password Upstash |
| `JWT_SECRET` | chuỗi random ≥ 32 ký tự |
| `INTERNAL_API_KEY` | chuỗi random ≥ 32 ký tự |
| `ADAPTIVE_ENGINE_URL` | `https://awb-engine.fly.dev` |
| `CORS_ALLOWED_ORIGINS` | để trống tạm, cập nhật sau khi có URL Cloudflare Pages |

3. Nhấn **Save** sau mỗi secret

> Tạo `JWT_SECRET` và `INTERNAL_API_KEY` random: chạy `openssl rand -base64 48` trên terminal bất kỳ, hoặc dùng [randomkeygen.com](https://randomkeygen.com).

### Cách B — CLI (1 lệnh)

```bash
flyctl secrets set --app awb-backend \
  DB_URL="jdbc:postgresql://ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require" \
  DB_USER="your_neon_user" \
  DB_PASSWORD="your_neon_password" \
  NEO4J_URI="neo4j+s://xxxxxxxx.databases.neo4j.io" \
  NEO4J_USER="neo4j" \
  NEO4J_PASSWORD="your_neo4j_password" \
  REDIS_HOST="xxx.upstash.io" \
  REDIS_PORT="6379" \
  REDIS_PASSWORD="your_upstash_password" \
  JWT_SECRET="$(openssl rand -base64 48)" \
  INTERNAL_API_KEY="$(openssl rand -base64 32)" \
  ADAPTIVE_ENGINE_URL="https://awb-engine.fly.dev" \
  CORS_ALLOWED_ORIGINS="https://your-app.pages.dev"
```

---

## Bước 4 — Set secrets cho awb-engine

### Web UI

1. Vào [fly.io/apps/awb-engine/secrets](https://fly.io/apps/awb-engine/secrets)
2. Thêm 2 secrets:

| Key | Value |
|---|---|
| `JAVA_SERVICE_URL` | `https://awb-backend.fly.dev` |
| `INTERNAL_API_KEY` | cùng giá trị với backend |

### CLI

```bash
flyctl secrets set --app awb-engine \
  JAVA_SERVICE_URL="https://awb-backend.fly.dev" \
  INTERNAL_API_KEY="<cùng giá trị với backend>"
```

---

## Bước 5 — Deploy React lên Cloudflare Pages (web UI)

> Toàn bộ bước này làm trên trình duyệt, không cần CLI.

1. Đăng nhập [dash.cloudflare.com](https://dash.cloudflare.com)

2. Sidebar trái → **Workers & Pages**

3. Tab **Pages** → nút **Create a project**

4. Chọn **Connect to Git**
   - Nếu chưa kết nối GitHub: nhấn **Connect GitHub** → authorize Cloudflare trên GitHub → chọn repo `ai-wisdom-battle`
   - Nếu đã kết nối: tìm repo `ai-wisdom-battle` trong danh sách

5. Nhấn **Begin setup**, điền các trường:

   | Trường | Giá trị |
   |---|---|
   | **Project name** | `ai-wisdom-battle` |
   | **Production branch** | `master` |
   | **Framework preset** | `Vite` |
   | **Build command** | `npm run build` |
   | **Build output directory** | `dist` |
   | **Root directory (/)** | `frontend` |

6. Mở mục **Environment variables (advanced)** → **Add variable**:

   | Variable name | Value | Environment |
   |---|---|---|
   | `VITE_API_BASE_URL` | `https://awb-backend.fly.dev/api/v1` | Production |

7. Nhấn **Save and Deploy** → chờ build ~2 phút

8. Sau khi xong, Cloudflare hiện URL dạng `https://ai-wisdom-battle.pages.dev`
   - Nếu tên bị trùng, Cloudflare sẽ thêm suffix: `ai-wisdom-battle-xxx.pages.dev`

9. **Quan trọng**: Quay lại Fly.io → app `awb-backend` → **Secrets** → sửa `CORS_ALLOWED_ORIGINS` thành URL vừa lấy được

   Ví dụ: `https://ai-wisdom-battle.pages.dev`

---

## Bước 6 — Seed Neo4j Aura

Neo4j Aura không tự động seed. Vào **Neo4j Aura Console** → **Open** (mở Neo4j Browser) → dán nội dung file `docs/neo4j-schema.cypher` vào ô query và chạy.

Hoặc bằng CLI:

```bash
cypher-shell \
  -a "neo4j+s://xxxxxxxx.databases.neo4j.io" \
  -u neo4j \
  -p "your_neo4j_password" \
  -f docs/neo4j-schema.cypher
```

---

## Bước 7 — Kết nối CI/CD (GitHub Actions)

File `.github/workflows/deploy.yml` đã có sẵn. Sau lần đầu push lên `master`, deploy sẽ tự chạy nếu có đủ 3 secrets + 1 variable trong GitHub.

**GitHub repo → Settings → Secrets and variables → Actions**

Tab **Secrets** → **New repository secret**:

| Secret | Cách lấy |
|---|---|
| `FLY_API_TOKEN` | Terminal: `flyctl auth token` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare → **My Profile** → **API Tokens** → **Create Token** → template *Edit Cloudflare Pages* |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare dashboard → thanh bên phải trang chủ, mục *Account ID* |

Tab **Variables** → **New repository variable**:

| Variable | Giá trị |
|---|---|
| `VITE_API_BASE_URL` | `https://awb-backend.fly.dev/api/v1` |

Sau khi cấu hình xong: mỗi push lên `master` →
1. CI chạy tests
2. Nếu pass → deploy backend + engine + frontend song song tự động

---

## Kiểm tra toàn bộ sau deploy

```bash
# Backend health
curl https://awb-backend.fly.dev/actuator/health
# {"status":"UP"}

# Engine health
curl https://awb-engine.fly.dev/health
# {"status":"ok"}

# Đăng ký tài khoản thử
curl -s -X POST https://awb-backend.fly.dev/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "displayName":"Tester",
    "password":"Test1234!",
    "explorerType":"nature",
    "ageGroup":"adult_18_plus"
  }' | python3 -m json.tool

# Frontend — mở trình duyệt
# https://ai-wisdom-battle.pages.dev
```

---

## Logs và troubleshooting

### Xem logs qua web UI (không cần CLI)

- Fly.io: [fly.io/apps/awb-backend/monitoring](https://fly.io/apps/awb-backend/monitoring) → tab **Logs**
- Cloudflare Pages: dash.cloudflare.com → Workers & Pages → project → tab **Deployments** → chọn build → **View build log**

### Xem logs qua CLI

```bash
flyctl logs --app awb-backend
flyctl logs --app awb-engine
flyctl status --app awb-backend
flyctl ssh console --app awb-backend   # SSH debug
```

### Fly.io thiếu RAM cho Spring Boot?

Web UI: fly.io/apps/awb-backend → **Machines** → chọn machine → **Edit** → tăng Memory lên 512 MB

CLI: `flyctl scale memory 512 --app awb-backend`

### Neo4j Aura kết nối lỗi SSL?

URI phải dùng `neo4j+s://` (có `+s`). Kiểm tra secret `NEO4J_URI`.

### Redis kết nối lỗi?

Upstash yêu cầu TLS. `REDIS_SSL=true` đã set sẵn trong `fly.toml`.
`REDIS_HOST` chỉ dùng hostname thuần (không có prefix `rediss://`).

### Cloudflare Pages build lỗi "Cannot find module"?

Kiểm tra **Root directory** đã set là `frontend` (không phải để trống).

---

## Chi phí dự kiến

| Service | Free tier | Vượt free |
|---|---|---|
| Fly.io | $5 credit/tháng (~3 VM) | ~$2–5/VM/tháng |
| Neon | 512 MB, 1 project | $19/tháng |
| Neo4j Aura | 200K nodes | $65/tháng |
| Upstash | 10K cmd/ngày | $0.2/100K cmd |
| Cloudflare Pages | Unlimited | Free mãi |

Với traffic nhỏ (demo/MVP): **hoàn toàn miễn phí**.
