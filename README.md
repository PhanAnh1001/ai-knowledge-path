# AI Wisdom Battle

Nền tảng học tập hướng tò mò — kích thích khám phá tri thức thông qua knowledge graph và các phiên học thích nghi.

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
- [Cấu trúc project](#cấu-trúc-project)
- [Tài liệu kỹ thuật](#tài-liệu-kỹ-thuật)

---

## Tổng quan

**AI Wisdom Battle** là hệ thống đa thành phần cung cấp:

- Xác thực người dùng (JWT)
- Knowledge graph (Neo4j) kết nối các chủ đề tri thức liên ngành
- Phiên học thích nghi theo độ tuổi (`child_8_10`, `teen_11_17`, `adult_18_plus`)
- Phân loại người khám phá: `nature`, `technology`, `history`, `creative`
- Theo dõi chuỗi học tập và điểm số
- Adaptive Engine (Python) tự động điều chỉnh độ khó
- Frontend React cho trải nghiệm người dùng hiện đại

---

## Kiến trúc hệ thống

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

| Layer | Công nghệ |
|---|---|
| Backend Runtime | Java 21 |
| Backend Framework | Spring Boot 3.2.3 |
| Security | Spring Security + JWT (JJWT 0.12.5) |
| Relational DB | PostgreSQL 16 |
| Graph DB | Neo4j 5.18 (APOC) |
| Cache / Session | Redis 7 |
| ORM | JPA / Hibernate |
| Build | Maven 3.x |
| Frontend | React 18 + TypeScript + Vite + Tailwind CSS |
| State Management | Zustand + TanStack Query |
| Adaptive Engine | Python 3.12 + FastAPI + Pydantic |
| Reverse Proxy | Caddy |
| Container | Docker + Docker Compose |
| Testing (BE) | JUnit 5 + MockMvc + H2 |
| Testing (FE) | Vitest |
| Testing (Engine) | pytest + pytest-asyncio |

---

## Cài đặt nhanh (Docker)

**Yêu cầu:** Docker Desktop 24+ (hoặc Docker Engine + Compose plugin)

```bash
# 1. Clone repo
git clone <repo-url> ai-wisdom-battle
cd ai-wisdom-battle

# 2. Tạo file .env từ template
cp .env.example .env
# Chỉnh sửa .env: đặt mật khẩu mạnh cho POSTGRES, NEO4J, REDIS, JWT_SECRET

# 3. Khởi động toàn bộ stack
docker compose up -d

# 4. Kiểm tra sức khoẻ
curl http://localhost:8080/actuator/health
```

Ứng dụng khả dụng tại:
- **Backend API:** `http://localhost:8080`
- **Frontend:** `http://localhost:5173` (dev) hoặc `http://localhost:80` (prod)
- **Adaptive Engine:** `http://localhost:8001`

---

## Cài đặt môi trường phát triển

**Yêu cầu:** JDK 21, Maven 3.9+, Node 20+, Python 3.12+, Docker (cho database)

### Backend (Spring Boot)

```bash
# 1. Khởi động chỉ infrastructure (DB, Neo4j, Redis)
docker compose up -d postgres neo4j redis

# 2. Sao chép và cấu hình .env
cp .env.example .env

# 3. Export biến môi trường (hoặc dùng IntelliJ EnvFile plugin)
export $(grep -v '^#' .env | xargs)

# 4. Build
mvn clean package -DskipTests

# 5. Chạy ứng dụng
mvn spring-boot:run
```

### Frontend (React)

```bash
cd frontend
npm install
npm run dev     # Dev server tại http://localhost:5173
```

### Adaptive Engine (Python/FastAPI)

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
| `NEO4J_USER` | Username Neo4j | Có |
| `NEO4J_PASSWORD` | Mật khẩu Neo4j | Có |
| `REDIS_PASSWORD` | Mật khẩu Redis | Có |
| `JWT_SECRET` | Khoá bí mật JWT (≥ 32 ký tự) | Có |

> **Quan trọng:** Không commit file `.env` lên Git (đã có trong `.gitignore`).

---

## Chạy test

### Backend

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
npm test          # Chạy Vitest một lần
npm run test:watch  # Chế độ watch
```

### Adaptive Engine

```bash
cd adaptive-engine
pytest            # Chạy tất cả test
pytest tests/     # Chỉ thư mục tests
```

---

## Cấu trúc project

```
ai-wisdom-battle/
├── src/                          # Java Spring Boot backend
│   └── main/java/com/aiwisdombattle/
│       ├── controller/           # REST endpoints
│       ├── service/              # Business logic
│       ├── domain/
│       │   ├── entity/           # JPA entities (PostgreSQL)
│       │   └── model/            # Neo4j graph nodes
│       ├── dto/                  # Request / Response DTOs
│       ├── repository/           # JPA + Neo4j repositories
│       ├── security/             # JWT filter + token provider
│       ├── exception/            # Exception classes + GlobalExceptionHandler
│       └── config/               # Spring Security config
├── frontend/                     # React 18 + TypeScript + Vite + Tailwind
│   └── src/
├── adaptive-engine/              # Python FastAPI — tính toán độ khó thích nghi
│   ├── app/
│   └── tests/
├── docs/                         # Tài liệu kỹ thuật
├── docker/                       # Docker helper scripts
├── infra/                        # Infrastructure config
├── scripts/                      # Utility scripts
├── pom.xml                       # Maven build descriptor
├── Dockerfile                    # Backend Docker image
├── Caddyfile                     # Reverse proxy
├── docker-compose.yml            # Dev stack
└── docker-compose.prod.yml       # Production stack
```

---

## Tài liệu kỹ thuật

- [PRD — Product Requirements](docs/PRD.md)
- [API Endpoints](docs/api-endpoints.md)
- [PostgreSQL Schema](docs/database-schema.sql)
- [Neo4j Graph Schema](docs/neo4j-schema.cypher)
- [Project Log](docs/PROJECT_LOG.md)
- [Hướng dẫn Deploy](docs/DEPLOY.md)
- [Deploy miễn phí](docs/DEPLOY-FREE.md)
- [AI Assistant Guide](CLAUDE.md)
