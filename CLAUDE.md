# CLAUDE.md — AI Assistant Guide for ai-wisdom-battle

This file provides context and conventions for AI assistants (Claude and others) working on this repository.

## Project Overview

**AI Wisdom Battle** là nền tảng học tập hướng tò mò, kích thích khám phá tri thức thông qua knowledge graph và các phiên học thích nghi.

> **Trạng thái hiện tại (2026-03-23):** Đang migration từ Java/Spring Boot + Oracle Cloud sang **Go 1.22 + AWS Lightsail Singapore**. `backend-go/` là codebase active; `src/` (Java) và `adaptive-engine/` (Python) là legacy.

Hệ thống gồm:

1. **Go Backend** (`backend-go/`) — REST API, JWT, PostgreSQL (pgx), in-memory cache, adaptive difficulty tích hợp
2. **Java Backend** (`src/`) — Legacy Spring Boot, vẫn hoạt động trên Oracle VM
3. **Frontend React/TypeScript** (`frontend/`) — SPA với Vite + Tailwind CSS
4. **Adaptive Engine** (`adaptive-engine/`) — Legacy Python/FastAPI, đã merge logic vào Go backend

## Current Repository State

```
ai-wisdom-battle/
├── backend-go/                   # Go 1.22 backend (ACTIVE)
│   ├── cmd/server/               # Entry point: main.go
│   ├── internal/
│   │   ├── handler/              # HTTP handlers (Chi router)
│   │   ├── service/              # Business logic + adaptive engine
│   │   ├── repository/           # PostgreSQL queries (pgx/v5)
│   │   ├── middleware/           # JWT auth, CORS, rate limiting
│   │   ├── domain/               # Entities, DTOs
│   │   ├── cache/                # In-memory cache (sync.Map)
│   │   ├── config/               # App config
│   │   └── db/                   # DB connection + migrations
│   ├── pkg/                      # Shared utilities
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── src/                          # Java Spring Boot backend (LEGACY)
│   └── main/java/com/aiwisdombattle/
│       ├── AiWisdomBattleApplication.java
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
│   ├── src/
│   └── package.json
├── adaptive-engine/              # Python FastAPI micro-service (LEGACY)
│   ├── app/
│   ├── tests/
│   └── requirements.txt
├── infra/
│   ├── lightsail/                # Terraform cho AWS Lightsail (mới — active)
│   └── oracle/                   # Terraform cho Oracle Cloud (legacy)
├── docs/                         # Tài liệu kỹ thuật
│   ├── PRD.md
│   ├── MIGRATION-GO-LIGHTSAIL.md # Kế hoạch migration sang Go + Lightsail
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
├── .github/
│   └── workflows/
│       ├── ci.yml                # CI: build + test
│       ├── deploy.yml            # CD: deploy backend + frontend
│       └── terraform.yml         # Quản lý hạ tầng (Lightsail / Oracle)
├── docker/                       # Docker helper scripts
├── scripts/                      # Utility scripts
├── pom.xml                       # Maven build descriptor (legacy)
├── Dockerfile                    # Java backend Docker image (legacy)
├── Caddyfile                     # Reverse proxy config (Caddy)
├── docker-compose.yml            # Dev stack
├── docker-compose.prod.yml       # Production stack
├── .env.example                  # Mẫu biến môi trường
├── .gitignore
├── README.md
└── CLAUDE.md                     # This file
```

## Technology Stack

### Go Backend (Active)

| Layer | Công nghệ |
|---|---|
| Runtime | Go 1.22 |
| HTTP Router | Chi v5 |
| Security | JWT (golang-jwt/jwt v5) |
| Relational DB | PostgreSQL 16 (pgx/v5) |
| Cache | In-memory (sync.Map, TTL 10 phút) |
| Build | Go modules |
| Container | Docker + Docker Compose |
| Infra | AWS Lightsail Singapore (IPv4, ~$10/tháng) |

### Legacy Stack

| Layer | Công nghệ |
|---|---|
| Backend Runtime | Java 21 |
| Backend Framework | Spring Boot 3.2.3 |
| Security | Spring Security + JWT (JJWT 0.12.5) |
| Graph DB | Neo4j 5.18 (APOC) — bị bỏ trong Go backend |
| Cache / Session | Redis 7 — bị bỏ trong Go backend |
| Adaptive Engine | Python 3.12 + FastAPI — merged vào Go |
| Build | Maven 3.x |

### Shared

| Layer | Công nghệ |
|---|---|
| Frontend | React 18 + TypeScript + Vite + Tailwind CSS |
| State Management | Zustand + TanStack Query |
| Reverse Proxy | Caddy |
| Testing (Go) | go test + testify |
| Testing (Java) | JUnit 5 + MockMvc + H2 |
| Testing (FE) | Vitest |
| Testing (Engine) | pytest + pytest-asyncio |

## Migration Context

Dự án đang chuyển từ kiến trúc nặng (7 containers, ~5.3 GB RAM) sang kiến trúc nhẹ (3 containers, ~700 MB RAM):

| | Trước (Legacy) | Sau (Target) |
|---|---|---|
| Backend | Java 21 / Spring Boot 3.2 | Go 1.22 / Chi router |
| Graph DB | Neo4j 5.18 | PostgreSQL adjacency table |
| Cache | Redis 7 | In-memory (sync.Map) |
| Adaptive | Python FastAPI service | Merged vào Go |
| Infra | Oracle VM (free tier hết hạn) | AWS Lightsail Singapore $7/tháng |
| Frontend | Caddy + React SPA | Cloudflare Pages (free) |

Xem chi tiết: [`docs/MIGRATION-GO-LIGHTSAIL.md`](docs/MIGRATION-GO-LIGHTSAIL.md)

## Git Workflow

### Branching Strategy

- **`master`** — stable, production-ready code; never push directly
- **Feature branches** — all development happens on feature branches

### AI Assistant Branch Naming

AI-generated branches follow this convention:
```
claude/<description>-<sessionId>
```
Example: `claude/update-docs-0NlNK`

### Workflow for AI Assistants

1. Always develop on the designated feature branch (never `master`)
2. Commit changes with clear, descriptive messages
3. Push using: `git push -u origin <branch-name>`
4. If push fails due to network errors, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s)

### Commit Message Convention

Use imperative mood, present tense:
```
Add CLAUDE.md with project conventions
Fix null pointer in BattleEngine
Add unit tests for WisdomScorer
Update adaptive engine difficulty algorithm
Migrate auth handler to Go Chi router
```

## Build & Run

### Go Backend (Active)

```bash
cd backend-go

# Download dependencies
go mod download

# Run server
go run ./cmd/server

# Build binary
go build -o bin/server ./cmd/server

# Run tests
go test ./...
go test -v -cover ./...
```

### Java Backend (Legacy — Maven)

```bash
# Build
mvn clean package -DskipTests

# Run tests
mvn test

# Run the application
mvn spring-boot:run
```

### Frontend (Node/Vite)

```bash
cd frontend
npm install
npm run dev       # Dev server tại http://localhost:5173
npm run build     # Production build
npm test          # Vitest
```

### Adaptive Engine (Legacy — Python/FastAPI)

```bash
cd adaptive-engine
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
pytest            # Run tests
```

### Toàn bộ stack (Docker Compose)

```bash
# Dev (Go backend)
docker compose up -d

# Production
docker compose -f docker-compose.prod.yml up -d

# Kiểm tra sức khoẻ (Go)
curl http://localhost:8080/health

# Kiểm tra sức khoẻ (Java legacy)
curl http://localhost:8080/actuator/health
```

## Testing

### Go Backend

- Test đặt trong cùng package hoặc `*_test.go` files
- Dùng `go test ./...` để chạy toàn bộ
- Prefer table-driven tests
- Mock external dependencies (DB, cache) bằng interfaces

### Java Backend (JUnit 5 — Legacy)

- Đặt test trong `src/test/java/` theo cấu trúc package tương ứng
- Tên class test có hậu tố `Test` (e.g., `AuthServiceTest`)
- H2 in-memory cho unit/integration test — không cần Docker
- MockMvc cho controller tests

### Frontend (Vitest)

- Test đặt cạnh file source hoặc trong thư mục `__tests__`
- `npm test` chạy toàn bộ test suite

### Adaptive Engine (pytest — Legacy)

- Test đặt trong `adaptive-engine/tests/`
- `pytest` chạy toàn bộ; `pytest-asyncio` cho async endpoints

## Code Conventions

### Go (Backend)

- Packages: `lowercase` (e.g., `handler`, `service`, `repository`)
- Exported types/functions: `PascalCase`
- Unexported: `camelCase`
- Constants: `PascalCase` hoặc `UPPER_SNAKE_CASE` tuỳ context
- Error handling: luôn xử lý errors, không bỏ qua
- Interfaces: định nghĩa tại nơi dùng (consumer), không phải nơi implement
- Prefer standard library; hạn chế dependencies ngoài

### Java (Legacy Backend)

- Classes: `PascalCase`
- Methods và variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Packages: `lowercase.dotted` (e.g., `com.aiwisdombattle`)
- Document public APIs với Javadoc (tiếng Anh)

### TypeScript (Frontend)

- Components: `PascalCase`
- Functions và variables: `camelCase`
- Types/Interfaces: `PascalCase` với prefix `I` nếu cần phân biệt

### Python (Adaptive Engine — Legacy)

- Tuân theo PEP 8
- Type hints bắt buộc cho tất cả function signatures
- Docstrings theo Google style

## Environment Variables

Sao chép `.env.example` thành `.env`:

```bash
cp .env.example .env
```

Các biến cần thiết:

| Biến | Mô tả | Dùng ở |
|---|---|---|
| `POSTGRES_DB` | Tên database PostgreSQL | Go + Java |
| `POSTGRES_USER` | Username PostgreSQL | Go + Java |
| `POSTGRES_PASSWORD` | Mật khẩu PostgreSQL | Go + Java |
| `JWT_SECRET` | Khoá bí mật JWT (≥ 32 ký tự) | Go + Java |
| `NEO4J_USER` | Username Neo4j | Java legacy only |
| `NEO4J_PASSWORD` | Mật khẩu Neo4j | Java legacy only |
| `REDIS_PASSWORD` | Mật khẩu Redis | Java legacy only |

> **Quan trọng:** Không commit file `.env` lên Git (đã có trong `.gitignore`).

## Ngôn ngữ / Language

- Mọi phản hồi của AI assistant phải bằng **tiếng Việt**
- Mã nguồn, tên biến, comment trong code vẫn dùng tiếng Anh theo chuẩn Go/Java/TS/Python
- Tài liệu kỹ thuật (Godoc/Javadoc) dùng tiếng Anh; giải thích nội bộ dùng tiếng Việt

## CI/CD Workflows

| Workflow | File | Trigger | Chức năng |
|---|---|---|---|
| CI | `.github/workflows/ci.yml` | Push / PR | Build + test toàn bộ service |
| Deploy | `.github/workflows/deploy.yml` | CI pass trên `master` | Deploy Go backend (SSH) + frontend (Cloudflare Pages) |
| Terraform | `.github/workflows/terraform.yml` | Manual (`workflow_dispatch`) | Tạo / plan / destroy hạ tầng Lightsail / Oracle |

### GitHub Secrets cần thiết

**Cho Deploy workflow (Lightsail):**

| Secret | Mô tả |
|---|---|
| `LIGHTSAIL_VM_IP` | Public IP của Lightsail VM |
| `LIGHTSAIL_SSH_KEY` | Private key SSH để vào VM |
| `CLOUDFLARE_API_TOKEN` | CF token quyền "Edit Cloudflare Pages" |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID |

**Cho Terraform workflow (Lightsail):**

| Secret | Mô tả |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key |
| `SSH_PUBLIC_KEY` | SSH public key để vào VM |

**Legacy — Cho Oracle Cloud** (xem [`docs/GITHUB-SECRETS-SETUP.md`](docs/GITHUB-SECRETS-SETUP.md)):

| Secret | Mô tả |
|---|---|
| `OCI_TENANCY_OCID` | OCID tenancy Oracle Cloud |
| `OCI_USER_OCID` | OCID user API |
| `OCI_FINGERPRINT` | Fingerprint API key |
| `OCI_API_PRIVATE_KEY` | Nội dung file private key PEM |
| `OCI_REGION` | Region OCI |
| `OCI_COMPARTMENT_OCID` | OCID compartment |

## Tự review sau mỗi nhiệm vụ (BẮT BUỘC)

Sau khi hoàn thành bất kỳ nhiệm vụ nào, PHẢI tự thực hiện các bước sau TRƯỚC KHI kết thúc:

1. **General review** — Đứng trên các góc nhìn khác nhau để review lại câu trả lời.
2. **Security review** — Kiểm tra: injection (SQL/command/shell), XSS, broken auth, secrets hardcoded, insecure config, input validation thiếu.
3. **Syntax / logic** — Xác nhận code build được không lỗi, logic đúng với yêu cầu đề ra.
4. **Tests** — Chạy test suite phù hợp (`go test ./...` cho Go, `npm test` cho frontend) và xác nhận pass. Nếu không chạy được test, giải thích lý do.
5. **Docs** — Nếu có file document trong dự án liên quan đến nhiệm vụ, update luôn trước khi báo cáo hoàn thành.

Nếu phát hiện vấn đề ở bất kỳ bước nào, sửa trước khi báo cáo hoàn thành.

## Key Instructions for AI Assistants

1. **Always work on the designated branch** — never commit directly to `master`
2. **Go backend is primary** — khi thêm tính năng mới, implement trên `backend-go/`, không phải `src/` (Java)
3. **Read before editing** — understand existing code before proposing changes
4. **Minimal changes** — only change what is necessary; avoid refactoring unrelated code
5. **No security vulnerabilities** — avoid SQL injection, command injection, XSS, and other OWASP Top 10 issues
6. **Commit and push** — always commit your work and push to the remote branch when done
7. **Verify** — after making changes, confirm the build/tests still pass
8. **Ngôn ngữ phản hồi** — luôn trả lời bằng tiếng Việt trong tất cả các tương tác với người dùng
9. **Multi-service awareness** — khi thay đổi API contract, kiểm tra tác động lên frontend
10. **Migration-aware** — tránh thêm Neo4j/Redis dependencies vào code mới; dùng PostgreSQL + in-memory cache
