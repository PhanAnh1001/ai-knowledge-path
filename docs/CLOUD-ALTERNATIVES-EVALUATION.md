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

## 2. Phương án tối ưu Stack (giảm RAM requirement)

### Phương án A: Loại bỏ Neo4j → dùng PostgreSQL cho Knowledge Graph

**Ý tưởng:** Thay vì chạy Neo4j riêng (4GB RAM), dùng PostgreSQL có sẵn với:
- **Recursive CTEs** (`WITH RECURSIVE`) cho graph traversal
- Hoặc extension **Apache AGE** (hỗ trợ Cypher query trên PostgreSQL)
- Hoặc **pg_graph** (SQL/PGQ standard, PostgreSQL 18+)

**Ưu điểm:**
- Tiết kiệm **4GB RAM** (loại bỏ hoàn toàn Neo4j container)
- Giảm complexity vận hành (bớt 1 service + seeder)
- PostgreSQL recursive CTE đủ nhanh cho <10K nodes, <50K edges
- Không cần thay đổi data model nhiều (2 bảng: `nodes` + `edges`)

**Nhược điểm:**
- Cần refactor Neo4j repositories + Spring Data Neo4j sang JPA
- Graph traversal sâu (>3 levels) sẽ chậm hơn Neo4j
- Mất Cypher query language (trừ khi dùng Apache AGE)

**RAM sau tối ưu:**

| Service | RAM |
|---|---|
| Spring Boot | 2 GB (giảm vì bỏ Neo4j driver) |
| PostgreSQL | 2 GB (tăng nhẹ do thêm graph data) |
| Adaptive Engine | 512 MB |
| Redis | 256 MB |
| Caddy + Frontend | 100 MB |
| **Tổng** | **~5 GB** |

**Kết luận:** Cần VPS tối thiểu **8GB RAM** để có headroom.

---

### Phương án B: Giữ Neo4j nhưng giảm config

**Ý tưởng:** Giữ nguyên stack, tune Neo4j + JVM nhỏ hơn:
- Neo4j: heap 512MB, pagecache 256MB → container 1.5GB
- Spring Boot: JVM 1.5GB → container 2GB
- PostgreSQL: 1GB

**RAM sau tối ưu:**

| Service | RAM |
|---|---|
| Neo4j | 1.5 GB |
| Spring Boot | 2 GB |
| PostgreSQL | 1 GB |
| Adaptive Engine | 512 MB |
| Redis | 256 MB |
| Caddy + Frontend | 100 MB |
| **Tổng** | **~6 GB** |

**Kết luận:** Cần VPS tối thiểu **8GB RAM**. Performance Neo4j sẽ giảm đáng kể với graph lớn.

---

### Phương án C: Loại bỏ Neo4j + chuyển sang GraalVM Native Image

**Ý tưởng:** Kết hợp Phương án A + compile Spring Boot thành native image (GraalVM):
- Native image: startup <1s, RAM ~200-400MB thay vì 2-4GB
- Loại bỏ Neo4j hoàn toàn

**RAM sau tối ưu:**

| Service | RAM |
|---|---|
| Spring Boot (native) | 512 MB |
| PostgreSQL | 1 GB |
| Adaptive Engine | 512 MB |
| Redis | 256 MB |
| Caddy + Frontend | 100 MB |
| **Tổng** | **~2.5 GB** |

**Kết luận:** Cần VPS tối thiểu **4GB RAM**. Tuy nhiên cần effort lớn để chuyển sang GraalVM native (reflection config, compatibility issues).

---

## 3. So sánh Cloud Providers giá rẻ (tháng 3/2026)

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

## 4. Đề xuất: Top 3 phương án tốt nhất

### 🥇 Đề xuất 1 (Tốt nhất): Contabo 8GB + Loại bỏ Neo4j
- **Server:** Contabo VPS S — 4 vCPU, 8GB RAM, 75GB NVMe, unlimited bandwidth
- **Giá:** ~$3.90/tháng (hợp đồng 12 tháng) = **~$47/năm**
- **Stack thay đổi:** Neo4j → PostgreSQL (recursive CTEs hoặc Apache AGE)
- **RAM sử dụng:** ~5GB / 8GB available
- **Effort:** Trung bình — refactor Neo4j repositories sang JPA
- **Ưu điểm:** Giá cực rẻ, RAM thoải mái, unlimited bandwidth
- **Rủi ro:** Contabo IO có thể chậm hơn Hetzner; cần commit 12 tháng

### 🥈 Đề xuất 2 (Cân bằng): Hetzner CX32 8GB + Loại bỏ Neo4j
- **Server:** Hetzner CX32 — 4 vCPU, 8GB RAM, 80GB NVMe, 20TB bandwidth
- **Giá:** ~$7.40/tháng = **~$89/năm**
- **Stack thay đổi:** Neo4j → PostgreSQL
- **RAM sử dụng:** ~5GB / 8GB available
- **Effort:** Trung bình
- **Ưu điểm:** Hetzner nổi tiếng reliability + performance, thanh toán theo giờ (linh hoạt), NVMe nhanh, hỗ trợ tốt
- **Rủi ro:** Chỉ có datacenter EU (DE/FI) — latency cao nếu user ở VN/Asia

### 🥉 Đề xuất 3 (Ít thay đổi nhất): Contabo 16GB + Giữ nguyên stack
- **Server:** Contabo VPS L — 8 vCPU, 16GB RAM, 180GB NVMe, unlimited bandwidth
- **Giá:** ~$9.10/tháng (hợp đồng 12 tháng) = **~$109/năm**
- **Stack thay đổi:** Không — chỉ tune giảm memory limits trong docker-compose.prod.yml
- **RAM sử dụng:** ~10-12GB / 16GB available (tune Neo4j heap xuống 1GB)
- **Effort:** Thấp — chỉ cần thay đổi docker-compose config
- **Ưu điểm:** Không cần refactor code, đủ RAM cho stack hiện tại
- **Rủi ro:** Vẫn phụ thuộc Neo4j (phức tạp vận hành); Contabo IO

---

## 5. So sánh tổng hợp

| Tiêu chí | Đề xuất 1 (Contabo 8GB) | Đề xuất 2 (Hetzner 8GB) | Đề xuất 3 (Contabo 16GB) |
|---|---|---|---|
| **Chi phí/năm** | ~$47 | ~$89 | ~$109 |
| **Effort refactor** | Trung bình | Trung bình | Thấp |
| **Performance** | Tốt | Rất tốt | Tốt |
| **Reliability** | Khá | Rất tốt | Khá |
| **Flexibility** | Thấp (12-month lock) | Cao (hourly billing) | Thấp (12-month lock) |
| **Latency (Asia)** | EU/US | EU only | EU/US |
| **Stack simplicity** | Cao (bớt Neo4j) | Cao (bớt Neo4j) | Thấp (vẫn 6 services) |

---

## 6. Lộ trình thực hiện (nếu chọn Đề xuất 1 hoặc 2)

### Phase 1: Chuyển Knowledge Graph sang PostgreSQL (1-2 tuần)
1. Tạo schema mới trong PostgreSQL: `knowledge_nodes`, `knowledge_edges`
2. Viết migration script từ Neo4j Cypher data → SQL INSERT
3. Refactor `domain/model/` (Neo4j nodes) → JPA entities
4. Refactor `repository/` (Neo4j repositories) → JPA repositories với native SQL/recursive CTEs
5. Cập nhật `service/` layer để dùng JPA thay vì Neo4j driver
6. Loại bỏ Neo4j dependencies khỏi `pom.xml`
7. Cập nhật `docker-compose.prod.yml` — bỏ neo4j, neo4j-seeder services
8. Test toàn bộ knowledge graph features

### Phase 2: Tối ưu resource config (1-2 ngày)
1. Giảm Spring Boot memory: `-XX:MaxRAMPercentage=75.0` trong container 2GB
2. Giảm PostgreSQL shared_buffers phù hợp
3. Giảm Redis maxmemory xuống 128MB
4. Test load với config mới

### Phase 3: Deploy lên server mới (1 ngày)
1. Provision VPS (Contabo hoặc Hetzner)
2. Cài Docker + Docker Compose
3. Cập nhật CI/CD (SSH key, IP mới)
4. Deploy và verify
5. Cập nhật DNS

---

## 7. Tham khảo

- [Hetzner Cloud Pricing](https://www.hetzner.com/cloud)
- [Contabo VPS Plans](https://contabo.com/en-us/vps/)
- [Hetzner Price Adjustment April 2026](https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/)
- [Building Knowledge Graph with PostgreSQL (no Neo4j)](https://dev.to/micelclaw/4o-building-a-personal-knowledge-graph-with-just-postgresql-no-neo4j-needed-22b2)
- [Neo4j Alternatives 2026](https://www.puppygraph.com/blog/neo4j-alternatives)
- [Best Budget VPS 2026](https://hostadvice.com/vps/cheap-vps/)
- [Contabo Pricing Review](https://affinco.com/contabo-pricing/)
- [Hetzner Cloud Review 2026](https://betterstack.com/community/guides/web-servers/hetzner-cloud-review/)
