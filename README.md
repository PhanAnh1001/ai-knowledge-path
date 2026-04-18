# AI Knowledge Path

Nền tảng khám phá tri thức — nơi mỗi điều bạn hiểu mở ra ba điều mới, và mỗi session cảm giác như một chuyến phiêu lưu ngắn có hồi kết.

> **Trạng thái:** Đang migration từ Java/Spring Boot + Oracle Cloud sang **Go + AWS Lightsail**. Xem [`docs/MIGRATION-GO-LIGHTSAIL.md`](docs/MIGRATION-GO-LIGHTSAIL.md).

---

## Tầm nhìn

> Giúp trẻ em và người lớn yêu thích việc khám phá kiến thức — không phải bằng cách ép học, mà bằng cách làm cho kiến thức trở nên **không thể cưỡng lại**.

**AI Knowledge Path** không phải là một ứng dụng học tập thông thường. Đây là một **nền tảng khám phá** — mỗi session là một bí ẩn nhỏ cần giải mã, mỗi kiến thức học được mở ra 3 kiến thức mới qua knowledge graph, và động lực đến từ bên trong — không phải từ streak hay leaderboard.

---

## Vấn đề cần giải quyết

Các sản phẩm học tập hiện tại đều mắc cùng một nhóm lỗi:

| Vấn đề | Biểu hiện |
|---|---|
| **Động lực giả tạo** | Streak gây lo âu, leaderboard tạo mặc cảm, phần thưởng mất giá trị theo thời gian |
| **Học mà không hiểu** | Gamification lấn át nội dung — người dùng Duolingo 842 ngày vẫn không nói được |
| **Nội dung không liên quan** | Câu hỏi không gắn với sở thích hay cuộc sống người dùng |
| **Quá nông** | Chỉ kiểm tra bề mặt, không xây tư duy |
| **Paywall gây khó chịu** | Ẩn tính năng sau paywall hoặc giá $25/tháng cho nội dung hẹp |
| **Không cá nhân hóa** | Cùng một nội dung, cùng một độ khó cho tất cả |
| **Thiếu "khoảnh khắc wow"** | Không có bất ngờ, không có kết nối liên ngành, không có narrative |

**AI Knowledge Path** giải quyết bằng cách thay thế động lực ngoại sinh bằng 7 cơ chế nội sinh: Curiosity Gap, Identity-Based Progress, Knowledge Compounding, Social Sense-Making, Real-World Trigger, Expert Feeling, và Micro-Mystery Format.

---

## Cơ chế cốt lõi — Một Session (5–8 phút)

```
① Hook (30s)      — Câu hỏi bất ngờ tạo information gap
② Your Guess      — Người dùng đoán trước khi được giải thích
③ The Journey     — 3–4 màn hình ngắn, mỗi màn một insight
④ The Reveal      — Đối chiếu với dự đoán ban đầu (không có "sai hoàn toàn")
⑤ Teach It Back   — Giải thích lại cho nhân vật ảo (Feynman Technique)
⑥ The Payoff      — Knowledge graph cập nhật + 3 gợi ý session tiếp theo
```

---

## Mục lục

- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Tech Stack](#tech-stack)
- [Cài đặt nhanh (Docker)](#cài-đặt-nhanh-docker)
- [Cài đặt môi trường phát triển](#cài-đặt-môi-trường-phát-triển)
- [API](#api)
- [Biến môi trường](#biến-môi-trường)
- [Chạy test](#chạy-test)
- [Deploy lên AWS Lightsail](#deploy-lên-aws-lightsail)
- [Cấu trúc project](#cấu-trúc-project)
- [Tài liệu kỹ thuật](#tài-liệu-kỹ-thuật)

---

## Kiến trúc hệ thống

### Kiến trúc mới (Go + AWS Lightsail) — Target

```
Internet
    │
    ▼
Cloudflare (DNS + CDN + IPv4 proxy)
    │
    ├──▶ Cloudflare Pages — React SPA (free)
    │
    └──▶ AWS Lightsail Singapore (IPv4, ~$10/tháng)
             │
             ▼
         Caddy (reverse proxy, auto TLS via Cloudflare DNS)
             │
             ▼
         Go backend (Chi router, :8080)
             │
             └──▶ PostgreSQL 16 (local, :5432)
                     ├── users, knowledge_nodes, sessions
                     ├── user_node_progress
                     └── node_relations  ← thay Neo4j
```

### Kiến trúc cũ (Java + Oracle Cloud) — Legacy

```
┌─────────────────────────────────────────────────────────┐
│                    Caddy (Reverse Proxy)                 │
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
    ┌──────▼──────┐           ┌───────▼───────┐
    │  Frontend   │           │  Backend API  │
    │  React/TS   │           │  Spring Boot  │
    │  :5173/80   │           │    :8080      │
    └─────────────┘           └──┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
       ┌──────▼──────┐   ┌───────▼──────┐  ┌───────▼──────┐
       │ PostgreSQL  │   │    Neo4j     │  │    Redis     │
       │   :5432     │   │   :7474      │  │   :6379      │
       └─────────────┘   └──────────────┘  └──────────────┘
                                 │
                      ┌──────────▼──────────┐
                      │  Adaptive Engine    │
                      │  Python/FastAPI     │
                      │      :8001          │
                      └─────────────────────┘
```

---

## Tech Stack

| Layer | Go Backend (Active) | Legacy |
|---|---|---|
| Runtime | Go 1.22 | Java 21 / Spring Boot 3.2.3 |
| HTTP | Chi v5 | Spring MVC |
| DB | PostgreSQL 16 (pgx/v5) | PostgreSQL + Neo4j + Redis |
| Cache | In-memory sync.Map | Redis 7 |
| Auth | golang-jwt v5 | Spring Security + JJWT |
| Infra | AWS Lightsail Singapore | Oracle Cloud VM |
| Frontend | React 18 + TypeScript + Vite + Tailwind CSS | — |
| Testing | go test + testify / Vitest | JUnit 5 + MockMvc |

Migration từ 7 containers (~5.3 GB RAM) → 3 containers (~700 MB RAM). Xem [`docs/MIGRATION-GO-LIGHTSAIL.md`](docs/MIGRATION-GO-LIGHTSAIL.md).

---

## Cài đặt nhanh (Docker)

**Yêu cầu:** Docker Desktop 24+

```bash
# 1. Clone repo
git clone <repo-url> ai-knowledge-path
cd ai-knowledge-path

# 2. Tạo file .env từ template
cp .env.example .env
# Chỉnh sửa .env: đặt mật khẩu mạnh cho POSTGRES, JWT_SECRET

# 3. Khởi động stack
docker compose up -d

# 4. Kiểm tra sức khoẻ
curl http://localhost:8080/health
```

Ứng dụng khả dụng tại:
- **Backend API:** `http://localhost:8080`
- **Frontend:** `http://localhost:5173` (dev) hoặc `http://localhost:80` (prod)

---

## Cài đặt môi trường phát triển

### Go Backend

**Yêu cầu:** Go 1.22+, Docker (cho PostgreSQL)

```bash
docker compose up -d postgres
cp .env.example .env
cd backend-go
go mod download
go run ./cmd/server
```

### Frontend (React)

```bash
cd frontend
npm install
npm run dev     # Dev server tại http://localhost:5173
```

### Java Backend (Legacy)

```bash
docker compose up -d postgres neo4j redis
cp .env.example .env && export $(grep -v '^#' .env | xargs)
mvn clean package -DskipTests && mvn spring-boot:run
```

---

## API

**Base URL:** `http://localhost:8080/api/v1`
**Auth:** `Authorization: Bearer <access_token>`

### Xác thực

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| POST | `/auth/register` | Đăng ký tài khoản | Không |
| POST | `/auth/login` | Đăng nhập | Không |

**Đăng ký — `POST /auth/register`**
```json
{
  "email":        "user@example.com",
  "displayName":  "Khám Phá Gia",
  "password":     "Secret123",
  "explorerType": "nature",
  "ageGroup":     "teen_11_17"
}
```
→ `201 Created` — trả về `AuthResponse` (token + thông tin user)

**AuthResponse**
```json
{
  "accessToken":  "eyJ...",
  "tokenType":    "Bearer",
  "expiresIn":    86400000,
  "userId":       "uuid",
  "displayName":  "Khám Phá Gia",
  "explorerType": "nature",
  "ageGroup":     "teen_11_17",
  "premium":      false
}
```

### Knowledge Nodes

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/knowledge-nodes` | Danh sách chủ đề |
| GET | `/knowledge-nodes/{id}` | Chi tiết chủ đề |
| POST | `/knowledge-nodes` | Tạo chủ đề (admin) |

### Phiên học

| Method | Endpoint | Mô tả |
|---|---|---|
| POST | `/sessions/start` | Bắt đầu phiên học |
| GET | `/sessions/{id}` | Chi tiết phiên |
| POST | `/sessions/{id}/complete` | Hoàn thành phiên |
| GET | `/sessions/user/{userId}` | Lịch sử phiên của user |

Xem chi tiết tại [`docs/api-endpoints.md`](docs/api-endpoints.md).

---

## Biến môi trường

Sao chép `.env.example` thành `.env` và điền đầy đủ trước khi chạy:

| Biến | Mô tả | Bắt buộc |
|---|---|---|
| `POSTGRES_DB` | Tên database | Có |
| `POSTGRES_USER` | Username PostgreSQL | Có |
| `POSTGRES_PASSWORD` | Mật khẩu PostgreSQL | Có |
| `JWT_SECRET` | Khoá bí mật JWT (≥ 32 ký tự) | Có |
| `NEO4J_USER` | Username Neo4j (legacy) | Legacy only |
| `NEO4J_PASSWORD` | Mật khẩu Neo4j (legacy) | Legacy only |
| `REDIS_PASSWORD` | Mật khẩu Redis (legacy) | Legacy only |

> **Quan trọng:** Không commit file `.env` lên Git (đã có trong `.gitignore`).

---

## Chạy test

### Go Backend

```bash
cd backend-go
go test ./...                    # Tất cả tests
go test -v -cover ./...          # Với coverage
```

### Frontend

```bash
cd frontend
npm test
```

### Java Backend (Legacy)

```bash
mvn test
```

---

## Deploy lên AWS Lightsail

```
1. Cấu hình secrets  →  2. Terraform apply  →  3. CD tự động
   (1 lần duy nhất)       (tạo Lightsail VM)    (mỗi lần push master)
```

Secrets cần thiết:

| Secret | Mô tả |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `LIGHTSAIL_SSH_KEY` | Private key SSH để vào VM |
| `CLOUDFLARE_API_TOKEN` | CF token quyền "Edit Cloudflare Pages" |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID |

```bash
cd infra/lightsail
terraform init && terraform apply
```

Xem thêm: [docs/DEPLOY-LIGHTSAIL-DAY5.md](docs/DEPLOY-LIGHTSAIL-DAY5.md) | [docs/GITHUB-SECRETS-SETUP.md](docs/GITHUB-SECRETS-SETUP.md)

---

## Cấu trúc project

```
ai-knowledge-path/
├── backend-go/                   # Go 1.22 backend (Active)
│   ├── cmd/server/               # Entry point
│   ├── internal/
│   │   ├── handler/              # HTTP handlers (Chi)
│   │   ├── service/              # Business logic + adaptive engine
│   │   ├── repository/           # PostgreSQL queries (pgx)
│   │   ├── middleware/           # Auth JWT, CORS, rate limiting
│   │   ├── domain/               # Entities, DTOs
│   │   ├── cache/                # In-memory cache
│   │   └── db/                   # DB connection + migrations
│   └── pkg/                      # Shared utilities
├── src/                          # Java Spring Boot backend (Legacy)
├── frontend/                     # React 18 + TypeScript + Vite + Tailwind
├── adaptive-engine/              # Python FastAPI (Legacy — merged vào Go)
├── infra/
│   ├── lightsail/                # Terraform cho AWS Lightsail (active)
│   └── oracle/                   # Terraform cho Oracle Cloud (legacy)
├── .github/workflows/            # CI + Deploy + Terraform
├── docs/                         # Tài liệu kỹ thuật
├── docker-compose.yml            # Dev stack
├── docker-compose.prod.yml       # Production stack
└── .env.example                  # Mẫu biến môi trường
```

---

## Tài liệu kỹ thuật

- [PRD — Product Requirements](docs/PRD.md)
- [Migration Plan: Go + AWS Lightsail](docs/MIGRATION-GO-LIGHTSAIL.md)
- [API Endpoints](docs/api-endpoints.md)
- [PostgreSQL Schema](docs/database-schema.sql)
- [Project Log](docs/PROJECT_LOG.md)
- [Deploy Lightsail](docs/DEPLOY-LIGHTSAIL-DAY5.md)
- [Hướng dẫn Deploy](docs/DEPLOY.md)
- [GitHub Secrets Setup](docs/GITHUB-SECRETS-SETUP.md)
- [AI Assistant Guide](CLAUDE.md)
