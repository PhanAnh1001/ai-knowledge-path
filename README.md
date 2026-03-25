# AI Wisdom Battle

Nền tảng học tập hướng tò mò — kích thích khám phá tri thức thông qua knowledge graph và các phiên học thích nghi.

> **Trạng thái:** Đang migration từ Java/Spring Boot + Oracle Cloud sang **Go + AWS Lightsail**. Xem [`docs/MIGRATION-GO-LIGHTSAIL.md`](docs/MIGRATION-GO-LIGHTSAIL.md).

---

## Mục lục

- [Tổng quan](#tổng-quan)
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

## Tổng quan

**AI Wisdom Battle** là hệ thống đa thành phần cung cấp:

- Xác thực người dùng (JWT)
- Knowledge graph kết nối các chủ đề tri thức liên ngành (PostgreSQL adjacency table)
- Phiên học thích nghi theo độ tuổi (`child_8_10`, `teen_11_17`, `adult_18_plus`)
- Phân loại người khám phá: `nature`, `technology`, `history`, `creative`
- Theo dõi chuỗi học tập và điểm số
- Adaptive difficulty tích hợp trực tiếp trong Go backend
- Frontend React cho trải nghiệm người dùng hiện đại

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

### Go Backend (Mới — Active Development)

| Layer | Công nghệ |
|---|---|
| Runtime | Go 1.22 |
| HTTP Router | Chi v5 |
| Security | JWT (golang-jwt/jwt v5) |
| Relational DB | PostgreSQL 16 (pgx/v5) |
| Cache | In-memory (sync.Map, TTL 10 phút) |
| Build | Go modules |
| Container | Docker + Docker Compose |
| Infra | AWS Lightsail Singapore (IPv4) |

### Java Backend (Legacy — Maintenance)

| Layer | Công nghệ |
|---|---|
| Runtime | Java 21 |
| Framework | Spring Boot 3.2.3 |
| Security | Spring Security + JWT (JJWT 0.12.5) |
| Relational DB | PostgreSQL 16 |
| Graph DB | Neo4j 5.18 (APOC) |
| Cache / Session | Redis 7 |
| Build | Maven 3.x |

### Frontend & Adaptive Engine

| Layer | Công nghệ |
|---|---|
| Frontend | React 18 + TypeScript + Vite + Tailwind CSS |
| State Management | Zustand + TanStack Query |
| Adaptive Engine | Python 3.12 + FastAPI + Pydantic (merged vào Go) |
| Reverse Proxy | Caddy |
| Testing (BE) | Go test + testify |
| Testing (FE) | Vitest |

---

## Cài đặt nhanh (Docker)

### Go Backend (Khuyến nghị)

**Yêu cầu:** Docker Desktop 24+ (hoặc Docker Engine + Compose plugin)

```bash
# 1. Clone repo
git clone <repo-url> ai-wisdom-battle
cd ai-wisdom-battle

# 2. Tạo file .env từ template
cp .env.example .env
# Chỉnh sửa .env: đặt mật khẩu mạnh cho POSTGRES, JWT_SECRET

# 3. Khởi động stack (Go backend)
docker compose up -d

# 4. Kiểm tra sức khoẻ
curl http://localhost:8080/health
```

### Java Backend (Legacy)

```bash
docker compose -f docker-compose.yml up -d
curl http://localhost:8080/actuator/health
```

Ứng dụng khả dụng tại:
- **Backend API:** `http://localhost:8080`
- **Frontend:** `http://localhost:5173` (dev) hoặc `http://localhost:80` (prod)

---

## Cài đặt môi trường phát triển

### Go Backend

**Yêu cầu:** Go 1.22+, Docker (cho PostgreSQL)

```bash
# 1. Khởi động PostgreSQL
docker compose up -d postgres

# 2. Sao chép và cấu hình .env
cp .env.example .env

# 3. Chạy Go backend
cd backend-go
go mod download
go run ./cmd/server

# 4. Chạy test
go test ./...
```

### Java Backend (Legacy)

**Yêu cầu:** JDK 21, Maven 3.9+, Docker (cho database)

```bash
# 1. Khởi động infrastructure (DB, Neo4j, Redis)
docker compose up -d postgres neo4j redis

# 2. Sao chép và cấu hình .env
cp .env.example .env
export $(grep -v '^#' .env | xargs)

# 3. Build và chạy
mvn clean package -DskipTests
mvn spring-boot:run
```

### Frontend (React)

```bash
cd frontend
npm install
npm run dev     # Dev server tại http://localhost:5173
```

### Adaptive Engine (Python/FastAPI — Legacy)

```bash
cd adaptive-engine
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
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

**Đăng nhập — `POST /auth/login`**
```json
{ "email": "user@example.com", "password": "Secret123" }
```
→ `200 OK` — trả về `AuthResponse`

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
go test ./internal/service/...   # Chỉ service tests
go test -v -cover ./...          # Với coverage
```

### Java Backend (Legacy)

```bash
# Chạy tất cả test (dùng H2 in-memory — không cần Docker)
mvn test

# Chạy test của một class cụ thể
mvn test -Dtest=AuthServiceTest

# Báo cáo coverage (Surefire)
mvn verify
```

### Frontend

```bash
cd frontend
npm test            # Chạy Vitest một lần
npm run test:watch  # Chế độ watch
```

### Adaptive Engine (Legacy)

```bash
cd adaptive-engine
pytest            # Chạy tất cả test
pytest tests/     # Chỉ thư mục tests
```

---

## Deploy lên AWS Lightsail

Hạ tầng mới dùng **AWS Lightsail Singapore (IPv4)** + Cloudflare proxy.

### Quy trình

```
1. Cấu hình secrets  →  2. Terraform apply  →  3. CD tự động
   (1 lần duy nhất)       (tạo Lightsail VM)    (mỗi lần push master)
```

### Bước 1 — Cấu hình GitHub Secrets

Xem hướng dẫn tại: **[docs/GITHUB-SECRETS-SETUP.md](docs/GITHUB-SECRETS-SETUP.md)**

Secrets cần thiết cho Lightsail:

| Secret | Mô tả |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `LIGHTSAIL_SSH_KEY` | Private key SSH để vào VM |
| `CLOUDFLARE_API_TOKEN` | CF token quyền "Edit Cloudflare Pages" |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID |

### Bước 2 — Tạo VM bằng Terraform

```bash
# Terraform module tại infra/lightsail/
cd infra/lightsail
terraform init
terraform plan
terraform apply
```

Hoặc qua GitHub Actions: **Actions → Terraform (Lightsail) → Run workflow**

### Bước 3 — CI/CD tự động

Sau khi VM đã sẵn sàng, mỗi lần push lên `master`:
- **CI** build + test Go backend
- **Deploy** SSH vào VM rebuild + restart Go backend
- **Frontend** deploy tự động lên Cloudflare Pages

Xem thêm: [docs/DEPLOY-LIGHTSAIL-DAY5.md](docs/DEPLOY-LIGHTSAIL-DAY5.md) | [docs/MIGRATION-GO-LIGHTSAIL.md](docs/MIGRATION-GO-LIGHTSAIL.md)

---

## Cấu trúc project

```
ai-wisdom-battle/
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
│   ├── pkg/                      # Shared utilities
│   ├── go.mod
│   └── Dockerfile
├── src/                          # Java Spring Boot backend (Legacy)
│   └── main/java/com/aiwisdombattle/
│       ├── controller/
│       ├── service/
│       ├── domain/
│       ├── dto/
│       ├── repository/
│       ├── security/
│       ├── exception/
│       └── config/
├── frontend/                     # React 18 + TypeScript + Vite + Tailwind
│   └── src/
├── adaptive-engine/              # Python FastAPI (Legacy — merged vào Go)
│   ├── app/
│   └── tests/
├── infra/
│   ├── lightsail/                # Terraform cho AWS Lightsail (mới)
│   └── oracle/                   # Terraform cho Oracle Cloud (legacy)
├── .github/
│   └── workflows/
│       ├── ci.yml                # Build + test
│       ├── deploy.yml            # Deploy backend + frontend
│       └── terraform.yml         # Quản lý hạ tầng
├── docs/                         # Tài liệu kỹ thuật
│   ├── PRD.md
│   ├── MIGRATION-GO-LIGHTSAIL.md # Kế hoạch migration
│   ├── CLOUD-ALTERNATIVES-EVALUATION.md
│   ├── DEPLOY-LIGHTSAIL-DAY5.md
│   ├── DEPLOY-ORACLE.md
│   ├── DEPLOY-TERRAFORM.md
│   ├── DEPLOY.md
│   ├── GITHUB-SECRETS-SETUP.md
│   ├── PROJECT_LOG.md
│   ├── api-endpoints.md
│   ├── database-schema.sql
│   └── neo4j-schema.cypher
├── docker/                       # Docker helper scripts
├── scripts/                      # Utility scripts
├── pom.xml                       # Maven (legacy)
├── Dockerfile                    # Java backend Docker image (legacy)
├── Caddyfile                     # Reverse proxy
├── docker-compose.yml            # Dev stack
├── docker-compose.prod.yml       # Production stack
└── .env.example                  # Mẫu biến môi trường
```

---

## Tài liệu kỹ thuật

### Migration & Cloud

- [Migration Plan: Go + AWS Lightsail](docs/MIGRATION-GO-LIGHTSAIL.md)
- [Cloud Alternatives Evaluation](docs/CLOUD-ALTERNATIVES-EVALUATION.md)
- [Deploy Lightsail (Day 5)](docs/DEPLOY-LIGHTSAIL-DAY5.md)
- [Deploy Oracle Cloud (Legacy)](docs/DEPLOY-ORACLE.md)
- [Deploy Terraform](docs/DEPLOY-TERRAFORM.md)

### Tài liệu chung

- [PRD — Product Requirements](docs/PRD.md)
- [API Endpoints](docs/api-endpoints.md)
- [PostgreSQL Schema](docs/database-schema.sql)
- [Neo4j Graph Schema (Legacy)](docs/neo4j-schema.cypher)
- [Project Log](docs/PROJECT_LOG.md)
- [Hướng dẫn Deploy](docs/DEPLOY.md)
- [Lấy GitHub Secrets](docs/GITHUB-SECRETS-SETUP.md)
- [AI Assistant Guide](CLAUDE.md)
