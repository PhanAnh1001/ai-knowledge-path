# Migration Plan: AWS Lightsail (Singapore) + Go Backend

> **Trạng thái:** Draft — 2026-03-23
> **Phương án:** ĐX 9 từ [CLOUD-ALTERNATIVES-EVALUATION.md](./CLOUD-ALTERNATIVES-EVALUATION.md)
> **Mục tiêu:** Rewrite Spring Boot → Go, bỏ Neo4j/Redis/Adaptive Engine, deploy lên AWS Lightsail Singapore IPv6-only + Cloudflare

---

## 1. Tóm tắt quyết định

| | Trước | Sau |
|---|---|---|
| **Backend** | Java 21 / Spring Boot 3.2 | Go 1.22 / Chi router |
| **Graph DB** | Neo4j 5.18 | PostgreSQL (adjacency table) |
| **Cache** | Redis 7 | In-memory (sync.Map / ristretto) |
| **Adaptive Engine** | Python FastAPI service | Merged vào Go backend |
| **Rate limiting** | Redis-based | In-memory (sliding window) |
| **Containers** | 7 (app + pg + neo4j + redis + engine + frontend + caddy) | 3 (go-app + postgres + caddy) |
| **RAM sử dụng** | ~5.3 GB | ~700 MB |
| **Server** | Oracle VM (hiện tại) | AWS Lightsail Singapore IPv6-only |
| **Giá** | ~$0/tháng (Oracle free tier, hết hạn) | **Free 3 tháng** → ~$7/tháng |
| **Frontend** | Caddy serving + React SPA | Cloudflare Pages (free) |

---

## 2. Kiến trúc mới

```
Internet
    │
    ▼
Cloudflare (DNS + CDN + IPv4 proxy)
    │
    ├──▶ Cloudflare Pages — React SPA (free)
    │
    └──▶ AWS Lightsail (Singapore, IPv6-only, $7/tháng)
             │
             ▼
         Caddy (reverse proxy, auto TLS via Cloudflare DNS challenge)
             │
             ▼
         Go backend (Chi router, port 8080)
             │
             ├──▶ PostgreSQL 16 (local, port 5432)
             │       ├── users
             │       ├── knowledge_nodes
             │       ├── sessions
             │       ├── user_node_progress
             │       └── node_relations  ← thay Neo4j
             │
             └── In-memory cache (node lists, TTL 10 phút)
```

**Lưu ý về IPv6-only + Cloudflare:**
- AWS Lightsail IPv6-only: không có IPv4 public address trực tiếp
- Cloudflare proxy trước domain → Cloudflare kết nối tới server qua IPv6
- User (IPv4 hoặc IPv6) → Cloudflare → IPv6 → server: hoàn toàn transparent
- Caddy dùng Cloudflare DNS-01 challenge để lấy SSL cert (không cần port 80 IPv4)

---

## 3. Thay đổi database schema

### 3.1 Bỏ Neo4j — thêm bảng `node_relations`

```sql
-- Thay thế toàn bộ Neo4j graph bằng 1 bảng
CREATE TABLE node_relations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_node_id    UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    to_node_id      UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    relation_type   VARCHAR(20) NOT NULL,  -- LEADS_TO | DEEP_DIVE | CROSS_DOMAIN
    weight          DOUBLE PRECISION DEFAULT 1.0,
    relation_vi     TEXT,   -- cho LEADS_TO
    concept         TEXT,   -- cho CROSS_DOMAIN
    insight_vi      TEXT,   -- cho CROSS_DOMAIN
    UNIQUE(from_node_id, to_node_id, relation_type)
);

CREATE INDEX idx_node_relations_from ON node_relations(from_node_id);
CREATE INDEX idx_node_relations_type ON node_relations(relation_type);
```

### 3.2 Các query Neo4j → PostgreSQL SQL

| Cypher query | SQL tương đương |
|---|---|
| `LEADS_TO` gợi ý 3 node tiếp theo | `SELECT to_node_id FROM node_relations WHERE from_node_id=$1 AND relation_type='LEADS_TO' AND to_node_id != ALL($2) ORDER BY weight DESC LIMIT 3` |
| Knowledge map subgraph | `SELECT DISTINCT from_node_id, to_node_id, relation_type, weight FROM node_relations WHERE from_node_id = ANY($1) OR to_node_id = ANY($1)` |
| Deep dive chain (1..3 bước) | Recursive CTE với max depth=3 |
| Cross-domain surprises | `SELECT to_node_id FROM node_relations WHERE from_node_id=$1 AND relation_type='CROSS_DOMAIN' ORDER BY random() LIMIT 2` |

### 3.3 Data migration: Neo4j → PostgreSQL
- Xuất tất cả relationship từ Neo4j thành CSV
- Import vào bảng `node_relations`
- Script migration: `scripts/migrate-neo4j-to-pg.py` (viết khi đến bước này)

---

## 4. SM-2 Spaced Repetition — Merge vào Go

Logic SM-2 trong Python Adaptive Engine được merge trực tiếp vào Go. Không cần HTTP call.

```go
// pkg/sm2/sm2.go
type SM2Result struct {
    NextInterval   int
    NewEasiness    float64
    NewRepetitions int
    NextReviewDate time.Time
    IsReset        bool
}

func Calculate(quality, currentInterval int, easiness float64, repetitions int) SM2Result {
    // Quality: 0-5 (mapped từ score 0-100: score/20)
    // Chuẩn SM-2 algorithm
    if quality < 3 {
        return SM2Result{NextInterval: 1, NewEasiness: easiness, NewRepetitions: 0, IsReset: true, ...}
    }
    newEasiness := easiness + (0.1 - float64(5-quality)*(0.08+float64(5-quality)*0.02))
    if newEasiness < 1.3 { newEasiness = 1.3 }
    var nextInterval int
    switch repetitions {
    case 0: nextInterval = 1
    case 1: nextInterval = 6
    default: nextInterval = int(math.Round(float64(currentInterval) * newEasiness))
    }
    return SM2Result{
        NextInterval:   nextInterval,
        NewEasiness:    newEasiness,
        NewRepetitions: repetitions + 1,
        NextReviewDate: time.Now().AddDate(0, 0, nextInterval),
    }
}

// AdaptiveScore: dùng công thức đơn giản, không cần HTTP call
func AdaptiveScore(rawScore, durationSeconds, difficulty int) float64 {
    base := float64(rawScore)
    diffBonus := float64(difficulty-1) * 2.0
    return math.Min(100, base+diffBonus)
}
```

---

## 5. Cấu trúc Go project

```
backend-go/
├── cmd/
│   └── server/
│       └── main.go              -- entrypoint
├── internal/
│   ├── config/
│   │   └── config.go            -- env vars, viper
│   ├── db/
│   │   ├── postgres.go          -- pgx pool setup
│   │   └── migrations/          -- SQL migration files (golang-migrate)
│   │       ├── 001_initial.up.sql
│   │       ├── 001_initial.down.sql
│   │       ├── 002_node_relations.up.sql
│   │       └── 002_node_relations.down.sql
│   ├── middleware/
│   │   ├── jwt.go               -- JWT auth middleware
│   │   ├── ratelimit.go         -- in-memory rate limiter
│   │   └── cors.go              -- CORS middleware
│   ├── handler/
│   │   ├── auth.go              -- POST /auth/register, login, /auth/me, refresh, logout
│   │   ├── session.go           -- POST /sessions, /sessions/complete
│   │   └── node.go              -- GET /nodes, /nodes/:id, /nodes/:id/map, deep-dive, cross-domain
│   ├── service/
│   │   ├── auth.go              -- business logic auth
│   │   ├── session.go           -- business logic session + SM-2
│   │   └── node.go              -- business logic nodes + cache
│   ├── repository/
│   │   ├── user.go              -- SQL queries users
│   │   ├── node.go              -- SQL queries knowledge_nodes + node_relations
│   │   ├── session.go           -- SQL queries sessions
│   │   └── progress.go          -- SQL queries user_node_progress
│   ├── domain/
│   │   ├── user.go              -- User struct
│   │   ├── node.go              -- KnowledgeNode, NodeRelation structs
│   │   ├── session.go           -- Session, UserNodeProgress structs
│   │   └── errors.go            -- domain error types
│   └── cache/
│       └── nodes.go             -- in-memory node cache (sync.Map + TTL)
├── pkg/
│   └── sm2/
│       └── sm2.go               -- SM-2 algorithm + adaptive scoring
├── go.mod
├── go.sum
├── Dockerfile
└── .env.example
```

---

## 6. Go dependencies

```go
// go.mod
module github.com/aiwisdombattle/backend

go 1.22

require (
    github.com/go-chi/chi/v5 v5.0.12          // HTTP router
    github.com/go-chi/cors v1.2.1              // CORS middleware
    github.com/jackc/pgx/v5 v5.5.5            // PostgreSQL driver
    github.com/golang-jwt/jwt/v5 v5.2.1       // JWT
    github.com/golang-migrate/migrate/v4 v4.17.0  // DB migrations
    golang.org/x/crypto v0.22.0               // bcrypt
    github.com/google/uuid v1.6.0             // UUID
    github.com/joho/godotenv v1.5.1           // .env loading
)
```

**Lưu ý không dùng:**
- Không dùng ORM (GORM, ent) — dùng pgx trực tiếp để tối giản và dễ debug
- Không dùng Redis — in-memory cache đủ cho node list (ít thay đổi)
- Không dùng external SM-2 library — tự implement (50 dòng)

---

## 7. API Contract (giữ nguyên 100%)

Frontend **không cần thay đổi**. Tất cả path, method, request/response format giữ nguyên.

### Endpoints giữ nguyên
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/auth/me
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
POST   /api/v1/sessions
POST   /api/v1/sessions/complete
GET    /api/v1/nodes
GET    /api/v1/nodes/:nodeId
GET    /api/v1/nodes/:nodeId/map
GET    /api/v1/nodes/:nodeId/deep-dive
GET    /api/v1/nodes/:nodeId/cross-domain
GET    /actuator/health   → /health (Caddy rewrite rule)
```

### JSON response format giữ nguyên
- `AuthResponse`, `UserProfileResponse`, `SessionStartResponse`, `SessionCompleteResponse`
- `KnowledgeNodeResponse` (6 fields giai đoạn học)
- Error format: vẫn dùng RFC 7807-like `{timestamp, status, error, message, path}`

---

## 8. Infrastructure: AWS Lightsail Setup

### 8.1 Provision instance

```bash
# AWS CLI hoặc qua console
aws lightsail create-instances \
  --instance-names awb-prod \
  --availability-zone ap-southeast-1a \
  --blueprint-id ubuntu_22_04 \
  --bundle-id nano_3_0 \      # $7/tháng IPv6-only: 2vCPU, 2GB RAM, 60GB SSD, 3TB transfer
  --ip-address-type ipv6 \
  --user-data file://scripts/lightsail-init.sh
```

### 8.2 lightsail-init.sh

```bash
#!/bin/bash
# Chạy khi instance khởi động lần đầu
apt-get update -y
apt-get install -y docker.io docker-compose-plugin git curl

# Enable Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# UFW firewall
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 443/udp   # HTTP/3 QUIC
ufw --force enable
```

### 8.3 Cloudflare setup

1. **Domain**: trỏ `api.aiwisdombattle.com` → AAAA record của Lightsail IPv6 IP
2. **Proxy**: bật Cloudflare proxy (orange cloud) → Cloudflare làm IPv4 bridge
3. **SSL mode**: Full (strict) — Caddy tự lấy cert
4. **Caddyfile** (cập nhật cho Lightsail):

```caddyfile
api.aiwisdombattle.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy localhost:8080
}
```

### 8.4 GitHub Secrets cần thêm

| Secret | Mô tả |
|---|---|
| `LIGHTSAIL_HOST` | IPv6 address của instance |
| `LIGHTSAIL_SSH_KEY` | Private key SSH |
| `CLOUDFLARE_API_TOKEN` | CF token để Caddy DNS challenge |

---

## 9. Docker Compose (production mới)

```yaml
# docker-compose.prod.yml (mới — 3 containers)
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pg_data:/var/lib/postgresql/data
    # Không expose port ra ngoài
    deploy:
      resources:
        limits:
          memory: 512m

  app:
    image: ghcr.io/aiwisdombattle/backend-go:${IMAGE_TAG:-latest}
    restart: unless-stopped
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRATION_MS: ${JWT_EXPIRATION_MS:-86400000}
      JWT_REFRESH_EXPIRATION_MS: ${JWT_REFRESH_EXPIRATION_MS:-2592000000}
      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS}
      RATE_LIMIT_MAX: ${RATE_LIMIT_AUTH_MAX:-20}
      RATE_LIMIT_WINDOW: ${RATE_LIMIT_AUTH_WINDOW:-60}
    ports:
      - "127.0.0.1:8080:8080"
    deploy:
      resources:
        limits:
          memory: 256m

  caddy:
    image: ghcr.io/aiwisdombattle/caddy-cf:latest  # Caddy + Cloudflare DNS plugin
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    environment:
      CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    deploy:
      resources:
        limits:
          memory: 64m

volumes:
  pg_data:
  caddy_data:
  caddy_config:
```

**RAM usage ước tính:**
- PostgreSQL: ~100 MB
- Go backend: ~50-100 MB
- Caddy: ~20 MB
- OS + buffer: ~200 MB
- **Tổng: ~370-420 MB / 2 GB** (còn 1.5 GB headroom)

---

## 10. CI/CD Pipeline (cập nhật)

### `.github/workflows/ci.yml` (cập nhật)

```yaml
jobs:
  test-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.22' }
      - run: cd backend-go && go test ./...

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd frontend && npm ci && npm test

  build-docker:
    needs: [test-go, test-frontend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/build-push-action@v5
        with:
          context: ./backend-go
          push: true
          tags: ghcr.io/aiwisdombattle/backend-go:${{ github.sha }}
```

### `.github/workflows/deploy.yml` (cập nhật)

```yaml
# Deploy backend lên Lightsail (SSH vào IPv6 address)
# Deploy frontend lên Cloudflare Pages
jobs:
  deploy-backend:
    steps:
      - name: Deploy to Lightsail
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.LIGHTSAIL_HOST }}
          username: ubuntu
          key: ${{ secrets.LIGHTSAIL_SSH_KEY }}
          script: |
            cd /app
            IMAGE_TAG=${{ github.sha }} docker compose -f docker-compose.prod.yml pull app
            IMAGE_TAG=${{ github.sha }} docker compose -f docker-compose.prod.yml up -d app
            docker compose -f docker-compose.prod.yml exec app ./migrate up

  deploy-frontend:
    steps:
      - uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: ai-wisdom-battle
          directory: frontend/dist
```

---

## 11. Kế hoạch thực thi — 5 ngày (Claude sessions)

### Day 1: Scaffold + Auth
**Mục tiêu:** Go server chạy được với auth endpoints

**Tasks:**
1. [ ] Khởi tạo `backend-go/` với `go mod init`
2. [ ] Setup Chi router, config loading (env), graceful shutdown
3. [ ] Setup pgx connection pool + health check endpoint
4. [ ] Viết DB migrations (001_initial.up.sql — copy từ database-schema.sql)
5. [ ] Implement `domain/user.go`, `repository/user.go`
6. [ ] Implement JWT middleware (access + refresh token, claim `type`)
7. [ ] Implement in-memory rate limiter (sliding window theo IP)
8. [ ] Implement `handler/auth.go` + `service/auth.go`:
   - POST `/api/v1/auth/register`
   - POST `/api/v1/auth/login`
   - GET `/api/v1/auth/me`
   - POST `/api/v1/auth/refresh`
   - POST `/api/v1/auth/logout` (stateless — client drops token)
9. [ ] Test thủ công với curl/httpie

**Deliverable:** `curl /api/v1/auth/register` hoạt động

---

### Day 2: DB Migration + Node endpoints
**Mục tiêu:** Knowledge node APIs hoạt động, Neo4j đã được thay thế

**Tasks:**
1. [ ] Viết migration `002_node_relations.up.sql` (bảng `node_relations`)
2. [ ] Implement `domain/node.go`, `repository/node.go`:
   - Tất cả SQL queries cho nodes
   - SQL thay thế 4 Cypher queries (LEADS_TO, map, deep-dive, cross-domain)
3. [ ] Implement in-memory cache (`cache/nodes.go`) với TTL 10 phút
4. [ ] Implement `service/node.go` + `handler/node.go`:
   - GET `/api/v1/nodes`
   - GET `/api/v1/nodes/:nodeId`
   - GET `/api/v1/nodes/:nodeId/map`
   - GET `/api/v1/nodes/:nodeId/deep-dive`
   - GET `/api/v1/nodes/:nodeId/cross-domain`
5. [ ] Viết script `scripts/migrate-neo4j-to-pg.py` để export Neo4j → CSV → INSERT

**Deliverable:** GET `/api/v1/nodes` trả danh sách nodes đúng format

---

### Day 3: Session + SM-2
**Mục tiêu:** Session flow hoàn chỉnh, SM-2 merged in-process

**Tasks:**
1. [ ] Implement `pkg/sm2/sm2.go` (SM-2 algorithm + adaptive scoring)
2. [ ] Implement `domain/session.go`, `repository/session.go`, `repository/progress.go`
3. [ ] Implement `service/session.go` + `handler/session.go`:
   - POST `/api/v1/sessions` (startSession)
   - POST `/api/v1/sessions/complete` (completeSession + SM-2 + gợi ý tiếp theo)
4. [ ] Unit tests cho SM-2 (`pkg/sm2/sm2_test.go`)
5. [ ] Integration test cho session flow

**Deliverable:** POST `/api/v1/sessions/complete` trả `nextSuggestions` đúng

---

### Day 4: Docker + Tests + Error handling
**Mục tiêu:** Production-ready, container chạy, tests pass

**Tasks:**
1. [ ] Viết `Dockerfile` cho Go backend (multi-stage: builder + distroless)
2. [ ] Cập nhật `docker-compose.yml` (dev: 3 containers)
3. [ ] Cập nhật `docker-compose.prod.yml` (prod: 3 containers + Caddy CF)
4. [ ] Cập nhật `Caddyfile` cho IPv6 Lightsail + Cloudflare DNS challenge
5. [ ] RFC 7807 error middleware (format như Java GlobalExceptionHandler)
6. [ ] Viết Go tests cho các handlers (`handler/*_test.go`)
7. [ ] Cập nhật `.github/workflows/ci.yml` (Go build + test)
8. [ ] Cập nhật `.github/workflows/deploy.yml` (Lightsail deploy)
9. [ ] Cập nhật `.env.example` (bỏ NEO4J, REDIS, ADAPTIVE_ENGINE vars)

**Deliverable:** `docker compose up` chạy được, `go test ./...` pass

---

### Day 5: Lightsail Setup + Deploy + Data Migration
**Mục tiêu:** Production live trên Lightsail Singapore

**Tasks:**
1. [ ] Provision AWS Lightsail instance (ap-southeast-1, IPv6-only, $7/tháng plan)
2. [ ] Chạy `lightsail-init.sh` (Docker setup, firewall)
3. [ ] Setup Cloudflare:
   - AAAA record → Lightsail IPv6
   - Proxy mode ON
   - SSL Full (strict)
4. [ ] Setup GitHub Secrets (`LIGHTSAIL_HOST`, `LIGHTSAIL_SSH_KEY`, `CLOUDFLARE_API_TOKEN`)
5. [ ] Chạy `scripts/migrate-neo4j-to-pg.py` → export Neo4j data
6. [ ] Deploy first version + import data
7. [ ] Smoke test toàn bộ API endpoints
8. [ ] Smoke test frontend kết nối backend mới

**Deliverable:** Production live, frontend hoạt động end-to-end

---

## 12. Rủi ro và mitigation

| Rủi ro | Khả năng | Mitigation |
|---|---|---|
| Recursive CTE cho deep-dive chậm hơn Cypher | Thấp | Max depth 3, indexed, data nhỏ (<1000 nodes ban đầu) |
| In-memory cache mất khi restart | Chấp nhận | Node list cache warm lại ngay sau restart (<100ms) |
| Lightsail IPv6-only không reach được một số services | Thấp | Chỉ outbound: GitHub Container Registry (IPv6 OK), Cloudflare (IPv6 OK) |
| SM-2 kết quả khác với Python engine | Thấp | Unit test so sánh output với Python reference implementation |
| Caddy DNS challenge Cloudflare rate limit | Rất thấp | Cert được cache, chỉ renew 60 ngày/lần |
| Data loss khi migrate Neo4j → PostgreSQL | Thấp | Giữ Neo4j container chạy song song đến khi verify xong |

---

## 13. Rollback plan

**Nếu Go migration gặp vấn đề trong 5 ngày:**
- Oracle VM cũ vẫn còn Spring Boot stack → không có downtime
- Lightsail free trial → cancel bất kỳ lúc nào, không mất tiền
- Branch `claude/migrate-go-lightsail` riêng, không merge vào master đến khi smoke test pass

**Sau khi live:**
- Keep PostgreSQL backup daily (pg_dump cron → S3 hoặc Lightsail snapshots)
- Lightsail instance snapshot trước mỗi lần deploy lớn

---

## 14. Phụ lục: Mapping Java → Go

### HTTP Status Codes
```go
// domain/errors.go
var (
    ErrNotFound         = errors.New("resource not found")
    ErrConflict         = errors.New("resource already exists")
    ErrInvalidCreds     = errors.New("invalid credentials")
    ErrUnauthorized     = errors.New("unauthorized")
    ErrValidation       = errors.New("validation failed")
)

// Middleware map errors → HTTP status
func errorToStatus(err error) int {
    switch {
    case errors.Is(err, ErrNotFound):     return 404
    case errors.Is(err, ErrConflict):     return 409
    case errors.Is(err, ErrInvalidCreds): return 401
    case errors.Is(err, ErrUnauthorized): return 401
    case errors.Is(err, ErrValidation):   return 400
    default:                              return 500
    }
}
```

### JWT Claims
```go
type Claims struct {
    jwt.RegisteredClaims
    Type string `json:"type"`  // "access" | "refresh"
}
// Subject = userId (UUID string) — giống Java
```

### In-memory Rate Limiter
```go
// middleware/ratelimit.go
// Sliding window, per-IP, chỉ áp dụng /api/v1/auth/**
type rateLimiter struct {
    mu      sync.Mutex
    windows map[string][]time.Time  // ip → timestamps
    max     int
    window  time.Duration
}
```

### Node Cache
```go
// cache/nodes.go
type NodeCache struct {
    mu       sync.RWMutex
    allNodes []domain.KnowledgeNode
    byDomain map[string][]domain.KnowledgeNode
    expiry   time.Time
    ttl      time.Duration
}
```

---

*Cập nhật lần cuối: 2026-03-23*
