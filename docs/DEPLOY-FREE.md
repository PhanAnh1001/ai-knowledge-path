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

## Bước 1 — Cài flyctl

```bash
curl -L https://fly.io/install.sh | sh
flyctl auth signup   # hoặc: flyctl auth login
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
2. Lấy:
   - **Endpoint** (host): `xxx.upstash.io`
   - **Port**: `6379`
   - **Password**: từ tab REST API hoặc Redis Details
3. Lưu: `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
4. `REDIS_SSL=true` (Upstash bắt buộc TLS — đã config sẵn trong `fly.toml`)

---

## Bước 3 — Deploy Spring Boot lên Fly.io

```bash
# Trong thư mục gốc project
flyctl launch --no-deploy --name awb-backend
# Khi hỏi "overwrite fly.toml?" → No (đã có sẵn)
# Region: sin (Singapore) hoặc nrt (Tokyo)
```

Đặt secrets (thay bằng giá trị thật):

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
  CORS_ALLOWED_ORIGINS="https://your-app.pages.dev" \
  ADAPTIVE_ENGINE_URL="https://awb-engine.fly.dev"
```

Deploy:

```bash
flyctl deploy --app awb-backend
```

Kiểm tra:

```bash
flyctl status --app awb-backend
curl https://awb-backend.fly.dev/actuator/health
# {"status":"UP"}
```

---

## Bước 4 — Deploy Python Engine lên Fly.io

```bash
cd adaptive-engine

flyctl launch --no-deploy --name awb-engine
# "overwrite fly.toml?" → No

flyctl secrets set --app awb-engine \
  JAVA_SERVICE_URL="https://awb-backend.fly.dev" \
  INTERNAL_API_KEY="<cùng giá trị với backend>"

flyctl deploy --app awb-engine
```

Kiểm tra:

```bash
curl https://awb-engine.fly.dev/health
# {"status":"ok"}
```

Sau đó cập nhật `ADAPTIVE_ENGINE_URL` trong backend nếu URL khác dự kiến:

```bash
flyctl secrets set --app awb-backend \
  ADAPTIVE_ENGINE_URL="https://awb-engine.fly.dev"
```

---

## Bước 5 — Deploy React lên Cloudflare Pages

### Tùy chọn A — Tự động qua GitHub (khuyến nghị)

1. [pages.cloudflare.com](https://pages.cloudflare.com) → **Create a project** → Connect to Git
2. Chọn repo → **Begin setup**:
   - **Build command**: `npm run build`
   - **Build output directory**: `dist`
   - **Root directory**: `frontend`
   - **Environment variable**:
     ```
     VITE_API_BASE_URL = https://awb-backend.fly.dev/api/v1
     ```
3. **Save and Deploy**

Mọi push lên `master` sẽ tự động rebuild và deploy frontend.

### Tùy chọn B — Deploy thủ công bằng CLI

```bash
npm install -g wrangler
wrangler login

cd frontend
VITE_API_BASE_URL=https://awb-backend.fly.dev/api/v1 npm run build

wrangler pages deploy dist --project-name ai-wisdom-battle
```

---

## Bước 6 — Seed Neo4j Aura

Neo4j Aura không tự động seed. Chạy một lần:

```bash
# Cài cypher-shell nếu chưa có
# https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/

cypher-shell \
  -a "neo4j+s://xxxxxxxx.databases.neo4j.io" \
  -u neo4j \
  -p "your_neo4j_password" \
  -f docs/neo4j-schema.cypher
```

Hoặc vào **Neo4j Aura Console** → **Open** → dán nội dung file `.cypher` và chạy.

---

## Bước 7 — Tự động deploy (CI/CD)

File `.github/workflows/deploy.yml` đã có sẵn. Thêm 3 secrets vào GitHub:

**GitHub repo → Settings → Secrets and variables → Actions → New repository secret:**

| Secret | Cách lấy |
|---|---|
| `FLY_API_TOKEN` | `flyctl auth token` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare → My Profile → API Tokens → Create Token (template: *Edit Cloudflare Pages*) |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare dashboard → bên phải trang chủ |

Sau khi cấu hình: mỗi lần push lên `master` →
1. CI chạy tests (ci.yml)
2. Nếu pass → deploy.yml tự động deploy backend + engine + frontend

---

## Kiểm tra toàn bộ sau deploy

```bash
# Backend
curl https://awb-backend.fly.dev/actuator/health

# Engine
curl https://awb-engine.fly.dev/health

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

# Frontend
# Mở trình duyệt: https://ai-wisdom-battle.pages.dev
```

---

## Logs và troubleshooting

```bash
# Logs backend
flyctl logs --app awb-backend

# Logs engine
flyctl logs --app awb-engine

# Xem thông tin machine
flyctl status --app awb-backend

# SSH vào container (debug)
flyctl ssh console --app awb-backend
```

### Fly.io 256MB không đủ cho Spring Boot?

```bash
# Tăng memory (vẫn nằm trong free allowance $5/tháng)
flyctl scale memory 512 --app awb-backend
```

### Neo4j Aura kết nối lỗi SSL?

URI phải dùng `neo4j+s://` (có `+s`). Kiểm tra `NEO4J_URI` secret.

### Redis kết nối lỗi?

Upstash yêu cầu TLS. `REDIS_SSL=true` đã set sẵn trong `fly.toml`.
Kiểm tra `REDIS_HOST` không có prefix `rediss://` — chỉ dùng hostname thuần.

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
