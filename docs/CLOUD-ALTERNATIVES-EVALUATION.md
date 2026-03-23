# Đánh giá phương án Cloud thay thế cho AI Wisdom Battle

> **Ngày đánh giá:** 2026-03-23
>
> **Bối cảnh:** Oracle Cloud Always Free (ARM A1 Flex, 4 OCPU, 24GB RAM, 100GB disk) không thể provision do lỗi **"Out of host capacity"** kéo dài. Cần tìm phương án thay thế với chi phí thấp nhất có thể.

---

## 1. Phân tích tài nguyên hiện tại

### Stack hiện tại chạy trên production (docker-compose.prod.yml)

| Service | RAM Limit | Vai trò |
|---|---|---|
| **Neo4j 5.18** | 4 GB | Knowledge graph (heap 1.5GB + pagecache 1GB) |
| **Spring Boot** | 4 GB | Backend API (JVM heap ~3GB) |
| **PostgreSQL 16** | 2 GB | Relational DB (users, sessions, quiz) |
| **Adaptive Engine** | 1 GB | Python FastAPI micro-service |
| **Redis 7** | 512 MB | Cache & session store |
| **Caddy 2** | ~50 MB | Reverse proxy + auto-SSL |
| **Frontend (Nginx)** | ~50 MB | Static files |
| **Tổng** | **~12 GB** | Cần máy ≥16GB để có headroom |

**Nhận xét:** Neo4j chiếm 4GB — là thành phần tốn RAM nhất. Spring Boot + Neo4j driver cũng cần thêm RAM trong JVM.

---

## 2. Phân tích chi tiết từng thành phần — cơ hội tối ưu

### 2.1 Neo4j (4GB) — CƠ HỘI LỚN NHẤT

**Hiện trạng:** Neo4j 5.18 Community chạy riêng container, heap 1.5GB + pagecache 1GB.

**Thay thế:** Dùng PostgreSQL có sẵn với:
- **Recursive CTEs** (`WITH RECURSIVE`) cho graph traversal
- Hoặc extension **Apache AGE** (hỗ trợ Cypher query trên PostgreSQL)
- Hoặc **pg_graph** (SQL/PGQ standard, PostgreSQL 18+)

**Tại sao khả thi:**
- Knowledge graph hiện tại ở quy mô nhỏ (<10K nodes, <50K edges)
- Recursive CTE với depth 2-3 chạy trong microseconds ở quy mô này
- Chỉ cần 2 bảng: `knowledge_nodes` + `knowledge_edges`

| | Neo4j | PostgreSQL (Recursive CTE) |
|---|---|---|
| RAM riêng | 4 GB | 0 (dùng chung PG) |
| Traversal <3 levels | Nhanh | Nhanh tương đương |
| Traversal >5 levels | Rất nhanh | Chậm hơn |
| Vận hành | Thêm 1 service + seeder | Không thêm gì |

**Tiết kiệm: ~4 GB RAM**, bỏ 2 containers (neo4j + neo4j-seeder).
**Effort:** Trung bình (~1-2 tuần) — refactor Neo4j repositories + Spring Data Neo4j sang JPA.

---

### 2.2 Adaptive Engine / Python FastAPI (1GB) — DỄ LOẠI BỎ NHẤT

**Hiện trạng:** Service Python riêng chạy FastAPI, 3 endpoints: `/scoring`, `/spaced-repetition`, `/recommendation`.

**Phát hiện quan trọng:** Sau khi phân tích toàn bộ code, logic **cực kỳ đơn giản**:

| Endpoint | Logic | Gọi DB? | Độ phức tạp |
|---|---|---|---|
| `/scoring` | Công thức toán: `raw_score x difficulty_bonus x speed_bonus x (1 - hint_penalty)` | Không | Rất thấp |
| `/spaced-repetition` | Thuật toán SM-2 (SuperMemo 2) — phép cộng/nhân cơ bản | Không | Thấp |
| `/recommendation` | Weighted scoring: 4 trọng số, sort, lấy top N | Không | Thấp |

**Đặc điểm:**
- **Zero external calls** — không gọi DB, không gọi API ngoài
- **Pure stateless math** — chỉ nhận input, tính toán, trả output
- **Java backend đã có sẵn DTO** (`ScoreRequest`, `ScoreResponse`) trong `AdaptiveEngineClient.java`
- Spring Boot gọi engine qua HTTP → overhead network không cần thiết

**Giải pháp: Merge logic vào Spring Boot** (inline Java methods thay vì HTTP calls)
- Copy 3 service classes Python → 3 Java service classes
- Thay `AdaptiveEngineClient` (HTTP) → inject local services
- **Effort: ~8-12 giờ** (port logic + viết unit tests)

**Tiết kiệm: ~1 GB RAM**, bỏ 1 container + 1 Docker image + giảm latency (không HTTP roundtrip).

---

### 2.3 Redis (512MB) — CÓ THỂ LOẠI BỎ

**Hiện trạng:** Redis dùng cho 3 mục đích:

| Mục đích | Cách dùng | Thay thế được? |
|---|---|---|
| **Session store** | `spring-session-data-redis` | Chuyển sang JWT stateless (đã có JWT!) |
| **Cache knowledge nodes** | `@Cacheable` — 2 cache keys, TTL 10 phút | Caffeine in-process cache |
| **Rate limiting auth** | `StringRedisTemplate` INCR/EXPIRE, 20 req/60s | Caffeine hoặc Bucket4j in-memory |

**Phát hiện quan trọng:** Project **đã dùng JWT** cho authentication! Việc dùng Redis cho session store là **thừa** — JWT token đã chứa đủ thông tin user, không cần server-side session.

**Giải pháp: Loại bỏ Redis hoàn toàn**
1. **Session:** Chuyển sang pure JWT stateless (bỏ `spring-session-data-redis`)
2. **Cache:** Thay `RedisCacheManager` → `CaffeineCacheManager` (in-process, ~5MB RAM)
3. **Rate limiting:** Thay `StringRedisTemplate` → `ConcurrentHashMap` + scheduled cleanup hoặc Bucket4j

**Tiết kiệm: ~512 MB RAM**, bỏ 1 container.
**Effort:** Thấp (~4-6 giờ) — thay dependencies + config, logic không đổi.

**Lưu ý:** Nếu sau này scale ra nhiều instances, sẽ cần Redis lại. Nhưng ở quy mô single-server thì in-process cache đủ tốt.

---

### 2.4 PostgreSQL (2GB) — GIỮ, GIẢM NHẸ

PostgreSQL là thành phần **bắt buộc** (relational data, Flyway migrations). Có thể tune:
- Giảm `shared_buffers` xuống 128MB
- Container limit 512MB-1GB là đủ cho quy mô nhỏ

**Tiết kiệm: ~1 GB** (từ 2GB xuống 1GB).

---

### 2.5 Spring Boot / JVM (4GB) — GIẢM MẠNH SAU KHI BỎ NEO4J

Sau khi bỏ Neo4j driver + Redis driver khỏi classpath:
- JVM footprint giảm đáng kể (bớt connection pools, bớt thread pools)
- Container 1-1.5GB là đủ (JVM heap ~768MB-1GB)
- Có thể giảm thêm nữa với GraalVM native image (200-400MB) nhưng effort lớn

**Tiết kiệm: ~2.5-3 GB** (từ 4GB xuống 1-1.5GB).

---

### 2.6 Frontend (Nginx) — KHÔNG CẦN TRÊN SERVER

Frontend React đã build thành static files → có thể host trên **Cloudflare Pages miễn phí** (CI/CD `deploy.yml` đã hỗ trợ). Không cần Nginx container trên VPS.

**Tiết kiệm: ~50 MB** + giảm complexity.

---

### 2.7 Caddy (50MB) — GIỮ

Caddy cần cho reverse proxy + auto-SSL (Let's Encrypt). Rất nhẹ, không cần thay đổi.

---

## 3. Tổng hợp các phương án tối ưu Stack

### Phương án A: Bỏ Neo4j (tiết kiệm 4GB)

Chỉ loại bỏ Neo4j → PostgreSQL recursive CTEs.

| Service | RAM |
|---|---|
| Spring Boot | 2 GB |
| PostgreSQL | 2 GB |
| Adaptive Engine | 512 MB |
| Redis | 256 MB |
| Caddy | 50 MB |
| **Tổng** | **~5 GB** |

**Effort:** Trung bình (1-2 tuần). Cần VPS **8GB RAM**.

---

### Phương án B: Bỏ Neo4j + Merge Adaptive Engine (tiết kiệm 5GB)

Kết hợp A + port Python logic vào Java.

| Service | RAM |
|---|---|
| Spring Boot | 2 GB |
| PostgreSQL | 2 GB |
| Redis | 256 MB |
| Caddy | 50 MB |
| **Tổng** | **~4.3 GB** |

**Effort:** Trung bình (1-2 tuần + 1-2 ngày). Cần VPS **8GB RAM**.

---

### Phương án C: Bỏ Neo4j + Merge Engine + Bỏ Redis (tiết kiệm 5.5GB)

Kết hợp B + thay Redis bằng Caffeine + pure JWT stateless.

| Service | RAM |
|---|---|
| Spring Boot | 1.5 GB (bỏ thêm Redis driver) |
| PostgreSQL | 1 GB |
| Caddy | 50 MB |
| **Tổng** | **~2.5 GB** |

**Chỉ còn 3 containers!** Effort: Trung bình (~2-3 tuần tổng). Cần VPS **4GB RAM**.

---

### Phương án D: Phương án C + GraalVM Native Image (tối ưu tối đa)

Kết hợp C + compile Spring Boot native image.

| Service | RAM |
|---|---|
| Spring Boot (native) | 400 MB |
| PostgreSQL | 512 MB |
| Caddy | 50 MB |
| **Tổng** | **~1 GB** |

**Chỉ còn 3 containers, tổng ~1GB!** Nhưng effort GraalVM rất lớn (reflection config, compatibility). Cần VPS **2GB RAM**.

---

### Phương án E: Giữ Neo4j nhưng tune nhỏ (ít thay đổi code)

Không thay đổi architecture, chỉ giảm resource limits.

| Service | RAM |
|---|---|
| Neo4j | 1.5 GB |
| Spring Boot | 2 GB |
| PostgreSQL | 1 GB |
| Adaptive Engine | 512 MB |
| Redis | 256 MB |
| Caddy | 50 MB |
| **Tổng** | **~5.3 GB** |

**Effort:** Thấp (thay đổi docker-compose config). Cần VPS **8GB RAM**. Performance Neo4j giảm.

---

### Phương án F: Rewrite backend sang Go (tối ưu cực đoan)

**Ý tưởng:** Thay thế Spring Boot (Java/JVM) bằng Go (Gin/Echo/Chi) — ngôn ngữ compiled, không cần JVM, memory footprint cực thấp.

**Phân tích backend hiện tại:**
- **12 REST endpoints** (Auth: 5, KnowledgeNode: 5, Session: 2)
- **4 JPA entities** (User, KnowledgeNode, Session, UserNodeProgress)
- **~2500 LOC Java** — logic chủ yếu CRUD, không có algorithm phức tạp
- **Không dùng Spring-specific features nâng cao** (không Cloud Config, không Reactive, không Batch)

**Benchmark thực tế Go vs Spring Boot (2025-2026):**

| Metric | Spring Boot (JVM) | Spring Native (GraalVM) | **Go (Gin/Chi)** |
|---|---|---|---|
| Idle memory | 180-250 MB | 45-120 MB | **8-25 MB** |
| Under load (500 RPS) | 350-450 MB | 98-120 MB | **25-68 MB** |
| Startup time | 3-8 giây | <1 giây | **<100ms** |
| Binary size | ~50 MB JAR + 200MB JRE | ~80 MB native | **~15 MB** |
| Docker image | ~300 MB | ~100 MB | **~20 MB** |

**Go backend cho project này sẽ dùng:**
- **HTTP:** Gin hoặc Chi (router + middleware)
- **ORM/SQL:** sqlx hoặc GORM (PostgreSQL)
- **JWT:** golang-jwt/jwt
- **Cache:** In-process (sync.Map hoặc go-cache)
- **Config:** envconfig hoặc viper
- **Validation:** go-playground/validator

**RAM sau tối ưu (Phương án F = Go + bỏ Neo4j/Redis/Engine):**

| Service | RAM |
|---|---|
| Go backend | 50-100 MB |
| PostgreSQL | 512 MB |
| Caddy | 50 MB |
| **Tổng** | **~700 MB** |

**Chỉ cần VPS 1-2GB RAM!**

**Effort:** Cao (~4-6 tuần) — rewrite ~2500 LOC Java sang Go.
Tuy nhiên logic đơn giản (CRUD + JWT + SM-2 math), Go syntax ngắn gọn hơn Java, nên thực tế có thể nhanh hơn GraalVM native image vì không cần xử lý reflection/compatibility issues.

---

### Phương án G: Rewrite backend sang Rust/Axum (tối ưu tối đa)

Tương tự Go nhưng memory thậm chí thấp hơn (~30MB under load). **Tuy nhiên learning curve cao hơn nhiều**, chỉ phù hợp nếu đã có kinh nghiệm Rust.

| Service | RAM |
|---|---|
| Rust backend (Axum) | 30-50 MB |
| PostgreSQL | 512 MB |
| Caddy | 50 MB |
| **Tổng** | **~600 MB** |

**Effort:** Rất cao (~6-10 tuần nếu chưa quen Rust).

---

### Phương án H: Rewrite backend sang Node.js/Fastify (cùng ngôn ngữ với frontend)

**Ưu điểm:** Frontend đã dùng TypeScript → cùng ngôn ngữ, chia sẻ types/validation schemas.

| Service | RAM |
|---|---|
| Node.js backend (Fastify) | 80-150 MB |
| PostgreSQL | 512 MB |
| Caddy | 50 MB |
| **Tổng** | **~800 MB** |

**Effort:** Trung bình (~3-4 tuần). Ecosystem quen thuộc hơn Go/Rust.

---

### So sánh tất cả phương án thay đổi backend language

| Phương án | Backend | RAM backend | RAM tổng | Effort | VPS tối thiểu |
|---|---|---|---|---|---|
| **C** (giữ Java) | Spring Boot JVM | 1.5 GB | 2.5 GB | 2-3 tuần | 4 GB |
| **D** (Java native) | Spring Native (GraalVM) | 400 MB | 1 GB | 4-6 tuần | 2 GB |
| **F** (Go) | Go + Gin/Chi | 50-100 MB | **700 MB** | 4-6 tuần | **1-2 GB** |
| **G** (Rust) | Rust + Axum | 30-50 MB | **600 MB** | 6-10 tuần | **1-2 GB** |
| **H** (Node.js) | Fastify + TypeScript | 80-150 MB | **800 MB** | 3-4 tuần | **2 GB** |

**Nhận xét quan trọng:**
- Go cho **ROI tốt nhất**: memory gần bằng Rust nhưng effort thấp hơn nhiều
- GraalVM native image cho memory tương đương Node.js nhưng effort cao hơn và nhiều compatibility issues
- Node.js cho effort thấp nhất trong các lựa chọn rewrite (cùng TypeScript với frontend)
- Rust chỉ nên chọn nếu team đã có kinh nghiệm

---

## 4. So sánh Cloud Providers giá rẻ (tháng 3/2026)

### Tier 1: Giá rẻ nhất — 4GB RAM ($3.5–5/tháng)

| Provider | Plan | vCPU | RAM | Disk | Bandwidth | Giá/tháng | Ghi chú |
|---|---|---|---|---|---|---|---|
| **Hetzner CAX11** | ARM (Ampere) | 2 | 4 GB | 40 GB | 20 TB | **€3.79** (~$4.10) | ARM64, chỉ EU (DE/FI). Giá tốt nhất. |
| **Hetzner CX23** | Shared Intel/AMD | 2 | 4 GB | 40 GB | 20 TB | **€3.49** (~$3.80) | x86, chỉ EU. |

> **Phù hợp với:** Phương án C (native image, ~2.5GB RAM)

### Tier 2: Tối ưu nhất — 8GB RAM ($5–8/tháng)

| Provider | Plan | vCPU | RAM | Disk | Bandwidth | Giá/tháng | Ghi chú |
|---|---|---|---|---|---|---|---|
| **Contabo VPS S** | AMD EPYC | 4 | 8 GB | 75 GB NVMe | Unlimited | **€3.60** (~$3.90) | Hợp đồng 12 tháng. RAM/giá tốt nhất thị trường. |
| **Hetzner CX32** | Shared Intel/AMD | 4 | 8 GB | 80 GB | 20 TB | **€6.80** (~$7.40) | x86, EU only. |
| **Hetzner CAX21** | ARM (Ampere) | 4 | 8 GB | 80 GB | 20 TB | **€6.49** (~$7.00) | ARM64, EU only. |
| **OVHcloud VPS** | — | 2 | 4 GB | 80 GB | Unlimited | **€5.50** (~$6.00) | EU + thêm regions. |

> **Phù hợp với:** Phương án A hoặc B (~5-6GB RAM cần thiết)

### Tier 3: Thoải mái hơn — 16GB RAM ($7–12/tháng)

| Provider | Plan | vCPU | RAM | Disk | Bandwidth | Giá/tháng | Ghi chú |
|---|---|---|---|---|---|---|---|
| **Contabo VPS M** | AMD EPYC | 6 | 12 GB | 130 GB NVMe | Unlimited | **€5.60** (~$6.10) | Hợp đồng 12 tháng. |
| **Contabo VPS L** | AMD EPYC | 8 | 16 GB | 180 GB NVMe | Unlimited | **€8.40** (~$9.10) | Hợp đồng 12 tháng. Chạy được stack hiện tại. |
| **Hetzner CX42** | Shared Intel/AMD | 8 | 16 GB | 160 GB | 20 TB | **€14.40** (~$15.60) | EU only. |
| **Hetzner CAX31** | ARM (Ampere) | 8 | 16 GB | 160 GB | 20 TB | **€12.49** (~$13.50) | ARM64, EU only. |

> **Phù hợp với:** Giữ nguyên stack hiện tại (tune nhẹ), hoặc Phương án A/B với headroom lớn

---

## 5. Đề xuất: Top 4 phương án kết hợp Server + Stack

### 🥇 Đề xuất 1 (Tốt nhất — giá/hiệu quả): Contabo 8GB + Phương án C
- **Server:** Contabo VPS S — 4 vCPU, 8GB RAM, 75GB NVMe, unlimited bandwidth
- **Giá:** ~$3.90/tháng (hợp đồng 12 tháng) = **~$47/năm**
- **Stack thay đổi:** Bỏ Neo4j + Merge adaptive engine + Bỏ Redis
- **Containers:** 3 (Spring Boot + PostgreSQL + Caddy)
- **RAM sử dụng:** ~2.5GB / 8GB = dư rất nhiều headroom
- **Effort:** Trung bình (~2-3 tuần)
- **Ưu điểm:** Chi phí cực thấp, stack đơn giản (3 containers), thừa RAM để phát triển thêm
- **Rủi ro:** Contabo IO có thể chậm; 12-month lock-in

### 🥈 Đề xuất 2 (Cân bằng quality): Hetzner CX23 4GB + Phương án C
- **Server:** Hetzner CX23 — 2 vCPU, 4GB RAM, 40GB NVMe, 20TB bandwidth
- **Giá:** ~$3.80/tháng = **~$46/năm**
- **Stack thay đổi:** Bỏ Neo4j + Merge adaptive engine + Bỏ Redis
- **Containers:** 3 (Spring Boot + PostgreSQL + Caddy)
- **RAM sử dụng:** ~2.5GB / 4GB
- **Effort:** Trung bình (~2-3 tuần)
- **Ưu điểm:** Hetzner reliability, hourly billing (linh hoạt), NVMe nhanh
- **Rủi ro:** Chỉ EU datacenter; 4GB hơi tight nếu traffic tăng

### 🥉 Đề xuất 3 (Nhanh nhất): Contabo 8GB + Phương án E
- **Server:** Contabo VPS S — 4 vCPU, 8GB RAM, 75GB NVMe, unlimited bandwidth
- **Giá:** ~$3.90/tháng = **~$47/năm**
- **Stack thay đổi:** Không — chỉ tune docker-compose memory limits
- **Containers:** 7 (giữ nguyên)
- **RAM sử dụng:** ~5.3GB / 8GB
- **Effort:** Thấp (~1-2 ngày, chỉ config)
- **Ưu điểm:** Không refactor code, deploy nhanh
- **Rủi ro:** Neo4j với 1.5GB heap sẽ chậm nếu graph lớn; vẫn phức tạp vận hành

### Đề xuất 4 (Tiết kiệm nhất — nếu dám refactor sâu): Hetzner CX22 2GB + Phương án D
- **Server:** Hetzner CX22 — 2 vCPU, 2GB RAM, 20GB NVMe, 20TB bandwidth
- **Giá:** ~$3.29/tháng = **~$40/năm**
- **Stack thay đổi:** Bỏ Neo4j + Merge engine + Bỏ Redis + GraalVM native image
- **Containers:** 3 (Spring Boot native + PostgreSQL + Caddy)
- **RAM sử dụng:** ~1GB / 2GB
- **Effort:** Cao (~4-6 tuần, GraalVM compatibility issues)
- **Ưu điểm:** Chi phí thấp nhất có thể ($40/năm), startup <1s
- **Rủi ro:** GraalVM native image phức tạp; 2GB tight; effort lớn

### Đề xuất 5 (ROI cao nhất nếu sẵn sàng đổi ngôn ngữ): Hetzner CX22 2GB + Phương án F (Go)
- **Server:** Hetzner CX22 — 2 vCPU, 2GB RAM, 20GB NVMe, 20TB bandwidth
- **Giá:** ~$3.29/tháng = **~$40/năm**
- **Stack thay đổi:** Rewrite Spring Boot → Go (Gin/Chi) + bỏ Neo4j/Redis/Engine
- **Containers:** 3 (Go backend + PostgreSQL + Caddy)
- **RAM sử dụng:** ~700MB / 2GB — **headroom thoải mái**
- **Effort:** Cao (~4-6 tuần) nhưng đơn giản hơn GraalVM vì không có compatibility issues
- **Ưu điểm:** RAM cực thấp (50-100MB backend), startup <100ms, binary 15MB, Docker image 20MB. Go đơn giản, dễ maintain, không cần JVM/runtime
- **Rủi ro:** Cần biết Go; mất Spring ecosystem

---

## 7. So sánh tổng hợp

| Tiêu chí | ĐX 1 | ĐX 2 | ĐX 3 | ĐX 4 | ĐX 5 |
|---|---|---|---|---|---|
| **Server** | Contabo 8GB | Hetzner 4GB | Contabo 8GB | Hetzner 2GB | Hetzner 2GB |
| **Backend** | Java (JVM) | Java (JVM) | Java (JVM) | Java (Native) | **Go** |
| **Phương án** | C (bỏ 3 svc) | C (bỏ 3 svc) | E (giữ nguyên) | D (GraalVM) | F (Go rewrite) |
| **Chi phí/năm** | ~$47 | ~$46 | ~$47 | ~$40 | **~$40** |
| **Containers** | 3 | 3 | 7 | 3 | 3 |
| **RAM tổng** | 2.5 GB | 2.5 GB | 5.3 GB | 1 GB | **700 MB** |
| **RAM headroom** | 5.5 GB | 1.5 GB | 2.7 GB | 1 GB | **1.3 GB** |
| **Effort** | 2-3 tuần | 2-3 tuần | 1-2 ngày | 4-6 tuần | 4-6 tuần |
| **Reliability** | Khá | Rất tốt | Khá | Rất tốt | Rất tốt |
| **Complexity risk** | Thấp | Thấp | Trung bình | **Cao** (GraalVM) | **Trung bình** |
| **Maintainability** | Tốt | Tốt | Tốt | Khá | **Rất tốt** |

---

## 7. Lộ trình thực hiện (Đề xuất 1 — Phương án C)

### Phase 1: Merge Adaptive Engine vào Spring Boot (2-3 ngày)
1. Tạo 3 Java service classes:
   - `AdaptiveScoringService` (port từ `scoring_service.py`)
   - `SpacedRepetitionService` (port từ `spaced_repetition_service.py`)
   - `RecommendationService` (port từ `recommendation_service.py`)
2. Thay `AdaptiveEngineClient` (HTTP) → inject local services
3. Viết unit tests tương ứng
4. Loại bỏ adaptive-engine container khỏi docker-compose
5. Xóa dependency `httpx` trong AdaptiveEngineClient

### Phase 2: Loại bỏ Redis (1-2 ngày)
1. Bỏ `spring-session-data-redis` → dùng pure JWT stateless (đã có JWT!)
2. Thay `RedisCacheManager` → `CaffeineCacheManager` (thêm `spring-boot-starter-cache` + Caffeine dependency)
3. Thay `RateLimitFilter` (StringRedisTemplate) → `ConcurrentHashMap` + scheduled cleanup
4. Loại bỏ Redis container khỏi docker-compose
5. Loại bỏ `spring-boot-starter-data-redis` khỏi pom.xml

### Phase 3: Chuyển Knowledge Graph sang PostgreSQL (1-2 tuần)
1. Tạo Flyway migration: bảng `knowledge_nodes`, `knowledge_edges`
2. Viết migration script từ Neo4j Cypher data → SQL INSERT
3. Refactor `domain/model/` (Neo4j `@Node`) → JPA `@Entity`
4. Refactor `repository/` (Neo4j repositories) → JPA repositories + native SQL recursive CTEs
5. Cập nhật `service/` layer
6. Loại bỏ `spring-boot-starter-data-neo4j` khỏi pom.xml
7. Loại bỏ neo4j + neo4j-seeder containers
8. Test toàn bộ knowledge graph features

### Phase 4: Deploy lên server mới (1 ngày)
1. Provision VPS (Contabo hoặc Hetzner)
2. Cài Docker + Docker Compose
3. Cập nhật CI/CD (SSH key, IP mới)
4. Cập nhật `docker-compose.prod.yml` với memory limits mới
5. Deploy và verify
6. Cập nhật DNS
7. Frontend vẫn trên Cloudflare Pages (không thay đổi)

---

## 9. Tham khảo

### Cloud Providers
- [Hetzner Cloud Pricing](https://www.hetzner.com/cloud)
- [Contabo VPS Plans](https://contabo.com/en-us/vps/)
- [Hetzner Price Adjustment April 2026](https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/)
- [Hetzner Cloud Review 2026](https://betterstack.com/community/guides/web-servers/hetzner-cloud-review/)
- [Best Budget VPS 2026](https://hostadvice.com/vps/cheap-vps/)
- [Contabo Pricing Review](https://affinco.com/contabo-pricing/)

### Stack Alternatives
- [Building Knowledge Graph with PostgreSQL (no Neo4j)](https://dev.to/micelclaw/4o-building-a-personal-knowledge-graph-with-just-postgresql-no-neo4j-needed-22b2)
- [Neo4j Alternatives 2026](https://www.puppygraph.com/blog/neo4j-alternatives)

### Backend Language Comparisons
- [Spring Boot Native vs Go: Performance Comparison](https://ignaciosuay.com/spring-boot-native-vs-go-a-performance-comparison/)
- [Go vs Spring Boot: After 2 years with both in production](https://runtimerants.dev/posts/golang-vs-springboot)
- [Go vs Java 2026: Performance Comparison for Backend Services](https://backendbytes.com/articles/go-vs-java-2026-performance-showdown/)
- [Java vs Go vs Rust for Backend Development 2026](https://www.index.dev/skill-vs-skill/backend-java-spring-vs-go-vs-rust)
- [Rust Web Frameworks in 2026: Axum vs Actix Web vs Rocket](https://aarambhdevhub.medium.com/rust-web-frameworks-in-2026-axum-vs-actix-web-vs-rocket-vs-warp-vs-salvo-which-one-should-you-2db3792c79a2)
