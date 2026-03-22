# CLAUDE.md — AI Assistant Guide for ai-wisdom-battle

This file provides context and conventions for AI assistants (Claude and others) working on this repository.

## Project Overview

**AI Wisdom Battle** là nền tảng học tập hướng tò mò, kích thích khám phá tri thức thông qua knowledge graph và các phiên học thích nghi. Hệ thống bao gồm ba thành phần chính:

1. **Backend Java/Spring Boot** — REST API, xác thực JWT, tích hợp PostgreSQL, Neo4j, Redis
2. **Frontend React/TypeScript** — SPA với Vite + Tailwind CSS
3. **Adaptive Engine (Python/FastAPI)** — dịch vụ micro tính toán độ khó thích nghi

## Current Repository State

```
ai-wisdom-battle/
├── src/                          # Java Spring Boot backend
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
├── adaptive-engine/              # Python FastAPI micro-service
│   ├── app/
│   ├── tests/
│   └── requirements.txt
├── docs/                         # Tài liệu kỹ thuật
│   ├── PRD.md
│   ├── api-endpoints.md
│   ├── database-schema.sql
│   ├── neo4j-schema.cypher
│   ├── PROJECT_LOG.md
│   ├── DEPLOY.md
│   ├── DEPLOY-ORACLE.md
│   ├── DEPLOY-TERRAFORM.md
│   └── GITHUB-SECRETS-SETUP.md
├── .github/
│   └── workflows/
│       ├── ci.yml                # CI: build + test
│       ├── deploy.yml            # CD: deploy backend lên Oracle VM, frontend lên Cloudflare
│       └── terraform.yml         # Tạo/phá hạ tầng Oracle Cloud qua GitHub Actions
├── docker/                       # Docker helper scripts
├── infra/                        # Infrastructure config (Terraform, v.v.)
├── scripts/                      # Utility scripts
├── pom.xml                       # Maven build descriptor
├── Dockerfile                    # Backend Docker image
├── Caddyfile                     # Reverse proxy config (Caddy)
├── docker-compose.yml            # Dev stack
├── docker-compose.prod.yml       # Production stack
├── .env.example                  # Mẫu biến môi trường
├── .gitignore
├── README.md
└── CLAUDE.md                     # This file
```

## Technology Stack

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
```

## Build & Run

### Backend (Maven)

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

### Adaptive Engine (Python/FastAPI)

```bash
cd adaptive-engine
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
pytest            # Run tests
```

### Toàn bộ stack (Docker Compose)

```bash
# Dev
docker compose up -d

# Production
docker compose -f docker-compose.prod.yml up -d

# Kiểm tra sức khoẻ
curl http://localhost:8080/actuator/health
```

## Testing

### Backend (JUnit 5)

- Đặt test trong `src/test/java/` theo cấu trúc package tương ứng
- Tên class test có hậu tố `Test` (e.g., `AuthServiceTest`)
- H2 in-memory cho unit/integration test — không cần Docker
- MockMvc cho controller tests

### Frontend (Vitest)

- Test đặt cạnh file source hoặc trong thư mục `__tests__`
- `npm test` chạy toàn bộ test suite

### Adaptive Engine (pytest)

- Test đặt trong `adaptive-engine/tests/`
- `pytest` chạy toàn bộ; `pytest-asyncio` cho async endpoints

## Code Conventions

### Java (Backend)

- Classes: `PascalCase`
- Methods và variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Packages: `lowercase.dotted` (e.g., `com.aiwisdombattle`)
- Prefer immutability where practical
- Document public APIs với Javadoc (tiếng Anh)

### TypeScript (Frontend)

- Components: `PascalCase`
- Functions và variables: `camelCase`
- Types/Interfaces: `PascalCase` với prefix `I` nếu cần phân biệt

### Python (Adaptive Engine)

- Tuân theo PEP 8
- Type hints bắt buộc cho tất cả function signatures
- Docstrings theo Google style

## Environment Variables

Sao chép `.env.example` thành `.env`:

```bash
cp .env.example .env
```

Các biến bắt buộc:

| Biến | Mô tả |
|---|---|
| `POSTGRES_DB` | Tên database PostgreSQL |
| `POSTGRES_USER` | Username PostgreSQL |
| `POSTGRES_PASSWORD` | Mật khẩu PostgreSQL |
| `NEO4J_USER` | Username Neo4j |
| `NEO4J_PASSWORD` | Mật khẩu Neo4j |
| `REDIS_PASSWORD` | Mật khẩu Redis |
| `JWT_SECRET` | Khoá bí mật JWT (≥ 32 ký tự) |

> **Quan trọng:** Không commit file `.env` lên Git (đã có trong `.gitignore`).

## Ngôn ngữ / Language

- Mọi phản hồi của AI assistant phải bằng **tiếng Việt**
- Mã nguồn, tên biến, comment trong code vẫn dùng tiếng Anh theo chuẩn Java/TS/Python
- Tài liệu kỹ thuật (Javadoc) dùng tiếng Anh; giải thích nội bộ dùng tiếng Việt

## CI/CD Workflows

| Workflow | File | Trigger | Chức năng |
|---|---|---|---|
| CI | `.github/workflows/ci.yml` | Push / PR | Build + test toàn bộ service |
| Deploy | `.github/workflows/deploy.yml` | CI pass trên `master` | Deploy backend (SSH) + frontend (Cloudflare Pages) |
| Terraform | `.github/workflows/terraform.yml` | Manual (`workflow_dispatch`) | Tạo / plan / destroy hạ tầng Oracle Cloud |

### GitHub Secrets cần thiết

**Cho Deploy workflow:**

| Secret | Mô tả |
|---|---|
| `ORACLE_VM_IP` | Public IP của Oracle VM |
| `ORACLE_SSH_KEY` | Private key SSH (ed25519) để vào VM |
| `CLOUDFLARE_API_TOKEN` | CF token quyền "Edit Cloudflare Pages" |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID |

**Cho Terraform workflow** (xem hướng dẫn đầy đủ tại [`docs/GITHUB-SECRETS-SETUP.md`](docs/GITHUB-SECRETS-SETUP.md)):

| Secret | Mô tả |
|---|---|
| `OCI_TENANCY_OCID` | OCID tenancy Oracle Cloud |
| `OCI_USER_OCID` | OCID user API |
| `OCI_FINGERPRINT` | Fingerprint API key |
| `OCI_API_PRIVATE_KEY` | Nội dung file private key PEM |
| `OCI_REGION` | Region OCI (vd: `ap-singapore-1`) |
| `OCI_COMPARTMENT_OCID` | OCID compartment (= tenancy với root) |
| `SSH_PUBLIC_KEY` | SSH public key để vào VM |

## Key Instructions for AI Assistants

1. **Always work on the designated branch** — never commit directly to `master`
2. **Read before editing** — understand existing code before proposing changes
3. **Minimal changes** — only change what is necessary; avoid refactoring unrelated code
4. **No security vulnerabilities** — avoid SQL injection, command injection, XSS, and other OWASP Top 10 issues
5. **Commit and push** — always commit your work and push to the remote branch when done
6. **Verify** — after making changes, confirm the build/tests still pass
7. **Ngôn ngữ phản hồi** — luôn trả lời bằng tiếng Việt trong tất cả các tương tác với người dùng
8. **Multi-service awareness** — khi thay đổi API contract, kiểm tra tác động lên cả frontend và adaptive-engine
