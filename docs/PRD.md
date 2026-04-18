# Product Requirements Document
## AI Knowledge Path — Nền tảng khám phá kiến thức

**Phiên bản:** 0.2 (Draft)
**Ngày:** 2026-03-21
**Trạng thái:** Concept / Pre-development

---

## 1. Tầm nhìn sản phẩm

> Giúp trẻ em và người lớn yêu thích việc khám phá kiến thức — không phải bằng cách ép học, mà bằng cách làm cho kiến thức trở nên không thể cưỡng lại.

Sản phẩm không phải là một ứng dụng học tập. Đây là một **nền tảng khám phá** — nơi mỗi điều bạn hiểu mở ra ba điều mới, và mỗi session cảm giác như một chuyến phiêu lưu ngắn có hồi kết.

---

## 2. Vấn đề cần giải quyết

### Pain points từ các sản phẩm hiện tại

| Nhóm | Vấn đề cụ thể |
|---|---|
| **Động lực giả tạo** | Streak gây lo âu, leaderboard tạo mặc cảm, phần thưởng mất giá trị theo thời gian |
| **Học mà không hiểu** | Gamification lấn át nội dung — người dùng Duolingo 842 ngày vẫn không nói được |
| **Nội dung không liên quan** | Câu hỏi không gắn với sở thích hay cuộc sống người dùng |
| **Quá nông** | Kahoot! chỉ kiểm tra bề mặt, không xây tư duy |
| **Paywall gây khó chịu** | Quizlet ẩn tính năng sau paywall, Brilliant $25/tháng cho nội dung hẹp |
| **Không cá nhân hóa** | Cùng một nội dung, cùng một độ khó cho tất cả |
| **Thiếu "khoảnh khắc wow"** | Không có bất ngờ, không có kết nối liên ngành, không có narrative |

---

## 3. Đối tượng người dùng

### Primary: Trẻ em 8–10 tuổi (lớp 2–4)
- Tò mò tự nhiên ở đỉnh cao, chưa có định kiến "học là nhàm"
- Học qua chuyện kể, hình ảnh, nhân vật — không qua text dài
- Cần môi trường an toàn tâm lý — không sợ sai
- Phụ huynh vẫn kiểm soát việc dùng app → kênh upsell Family Plan tự nhiên

### Secondary: Phụ huynh (người trả tiền)
- Muốn con học nhưng không muốn con nghiện màn hình vô bổ
- Cần bằng chứng con đang học thật sự
- Muốn kết nối với con qua việc học

### Tertiary: Người lớn tò mò (18–35 tuổi)
- Muốn học thêm nhưng không có thời gian cho khóa học dài
- Thích nội dung ngắn, sâu, liên kết liên ngành

---

## 4. Cơ chế động lực cốt lõi

Thay thế **động lực ngoại sinh** (streak, leaderboard, badge) bằng **động lực nội sinh**:

### 7 cơ chế chính

1. **Curiosity Gap Engine** — Đưa ra sự thật bất ngờ trước, để người dùng tự đoán cơ chế
2. **Identity-Based Progress** — Xây dựng bản sắc tri thức: *"Em có tư duy của một nhà thiên văn học"*
3. **Knowledge Compounding** — Mỗi kiến thức học được mở ra 3 kiến thức mới (knowledge graph)
4. **Social Sense-Making** — Hợp tác giải bí ẩn thay vì cạnh tranh điểm số
5. **Real-World Trigger** — Kiến thức xuất hiện đúng lúc liên quan đến cuộc sống người dùng
6. **Expert Feeling** — Dạy lại cho nhân vật ảo sau khi học (Feynman Technique)
7. **Micro-Mystery Format** — Mỗi session là một bí ẩn nhỏ cần giải mã

### Kiến trúc phân tầng

```
Tầng nền (luôn chạy ngầm)
├── Knowledge Compounding  → cấu trúc nội dung
└── Identity Building      → cấu trúc tiến trình

Tầng trải nghiệm (format học)
├── Micro-Mystery          → vỏ bọc câu chuyện
└── Curiosity Gap          → cơ chế kéo vào từng bài

Tầng tương tác (hành động người dùng)
├── Expert Feeling         → cuối mỗi chủ đề
└── Social Sense-Making    → tuỳ chọn, không bắt buộc

Tầng kết nối thực tế
└── Real-World Trigger     → điểm vào từ bên ngoài app
```

---

## 5. Điểm vào — Hệ thống 3 lớp Fallback

Người dùng không phải chủ động "đi học" — app tự tìm cách kết nối:

```
Lớp 1 (thử trước): Context-first
→ Gắn kiến thức với thứ đang xảy ra trong cuộc sống người dùng
→ Ví dụ: "Hôm nay trời mưa — tại sao sét đánh trước khi nghe sấm?"

Lớp 2 (fallback): Discovery-first
→ Câu hỏi phản trực giác dựa trên sở thích đã biết
→ Ví dụ: "Tại sao cá mập xuất hiện trước cả cây cối?"

Lớp 3 (safety net): Story-first
→ Câu chuyện đang dang dở của nhân vật, chờ tiếp tục
→ Ví dụ: "Luna đang khám phá hang động tối thì phát hiện..."
```

**Nguyên tắc chuyển lớp:** Liền mạch, vô hình — người dùng không biết có 3 lớp. Hệ thống tự học lớp nào hiệu quả với từng người.

---

## 6. Luồng Onboarding (5 bước, ~2 phút)

| Bước | Nội dung | Dữ liệu thu thập |
|---|---|---|
| 0 | Hook ngay: câu hỏi bất khả kháng trước khi hỏi bất cứ điều gì | Baseline curiosity |
| 1 | Chọn "kiểu nhà thám hiểm" (tự nhiên / công nghệ / lịch sử / sáng tạo) | Lĩnh vực hứng thú |
| 2 | "Em thường tò mò nhất lúc nào?" (sáng / tối / trên đường) | Thời điểm dùng app |
| 3 | Đặt tên + chọn avatar cho nhân vật | Neo identity |
| 4 | Màn hình đầu tiên đã cá nhân hóa ngay lập tức | Xác nhận hệ thống hoạt động |

---

## 7. Cấu trúc một Session học (5–8 phút)

```
① THE HOOK (30s)
   Câu hỏi bất ngờ tạo information gap
   → Không thể dừng lại được

② YOUR GUESS (45s)
   Người dùng đoán trước khi được giải thích
   → Kích hoạt prior knowledge, tạo cam kết tâm lý

③ THE JOURNEY (2–3 phút)
   3–4 màn hình ngắn, mỗi màn một insight
   → Tiết lộ kiến thức theo lớp, có nhịp điệu

④ THE REVEAL (30s)
   Đối chiếu với dự đoán ban đầu
   → Không có "sai hoàn toàn" — luôn tìm phần đúng

⑤ TEACH IT BACK (1 phút)
   Giải thích lại cho nhân vật ảo (Feynman Technique)
   → Sắp xếp mảnh ghép, không phải trắc nghiệm

⑥ THE PAYOFF (30s)
   Knowledge graph cập nhật + 3 gợi ý session tiếp theo
   → Reward intrinsic + mở cửa cho hành trình tiếp theo
```

---

## 8. Mô hình kinh doanh

### Triết lý
> Free phải đủ tốt để yêu thích. Premium phải đủ hấp dẫn để muốn.
> Monetize qua chiều sâu, không qua paywall.

### Cấu trúc gói

| Gói | Giá | Tính năng |
|---|---|---|
| **Free** | 0đ | 3 session/ngày, đầy đủ 6 giai đoạn, tất cả lĩnh vực |
| **Premium** | 79k/tháng | Session không giới hạn, Rabbit Hole Mode, Offline, Advanced Graph |
| **Family** | 149k/tháng | Premium × 3 hồ sơ + Parent Dashboard |
| **Annual** | -40% | Bất kỳ gói nào khi trả năm |

### Parent Dashboard (tính năng Family Plan)
- Bản đồ chủ đề con đã khám phá
- Câu hỏi con thường đặt ra
- Chế độ học cùng cả gia đình
- Gợi ý câu hỏi để bố mẹ thảo luận với con

### Nguyên tắc upsell
- Upsell đúng thời điểm cảm xúc cao nhất (vừa hoàn thành session, vừa mở node mới)
- Không bao giờ cắt ngang giữa session
- Không quảng cáo trong app
- Không khóa nội dung theo chủ đề

---

## 9. Chỉ số thành công (KPIs)

| Chỉ số | Mục tiêu giai đoạn đầu |
|---|---|
| D1 Retention | > 50% |
| D7 Retention | > 30% |
| Session completion rate | > 80% |
| Sessions per active user per day | 2–3 |
| Free → Premium conversion | > 8% |
| NPS | > 50 |

---

## 10. Những gì KHÔNG làm

- Không streak gây lo âu
- Không leaderboard cạnh tranh
- Không quảng cáo trong session
- Không paywall giữa chừng
- Không khóa chủ đề theo gói
- Không đối xử trẻ em và người lớn như nhau
- Không scope quá rộng ngay từ đầu

---

## 11. Lĩnh vực và nội dung MVP

### Lĩnh vực ra mắt
- **Khoa học tự nhiên** — hiện tượng hàng ngày, dễ visual, không tranh cãi
- **Danh nhân lịch sử** — narrative tự nhiên, cửa vào kiến thức liên ngành

### Danh nhân batch đầu tiên (7 nhân vật)
Marie Curie, Leonardo da Vinci, Nikola Tesla, Katherine Johnson,
Eratosthenes, Ibn Battuta, Ada Lovelace

### Mục tiêu nội dung 3 tháng đầu
```
Tháng 1: 50 session (30 khoa học cấp 1 + 20 danh nhân)
Tháng 2: 50 session (20 khoa học cấp 2 + 20 giao thoa + 10 danh nhân mới)
Tháng 3: Polish + 20 session buffer cho ngày ra mắt
```

### Quy trình tạo nội dung — Hybrid (Option C)
1. Content Designer viết session brief (15 phút)
2. AI draft toàn bộ 6 giai đoạn (5 phút)
3. Domain Expert review accuracy (20 phút)
4. Editor kiểm tra ngôn ngữ phù hợp 8–10 tuổi (10 phút)
5. QA + publish (10 phút)

**Tốc độ:** 4–6 session/ngày với team 2–3 người

### Team tối thiểu
- 1 Content Designer (full-time)
- 1 Expert khoa học tự nhiên (part-time)
- 1 Expert lịch sử (part-time)
- 1 Editor / UX Writer (full-time)

---

## 11. Rủi ro và câu hỏi còn mở

| Rủi ro | Mức độ | Cần làm rõ |
|---|---|---|
| Content production cost | Cao | AI-generated vs human-curated? |
| Cold start problem | Trung bình | Context-first cần dữ liệu — onboarding đủ không? |
| Scope quá rộng | Cao | Lĩnh vực nào ra mắt trước? |
| Child safety & COPPA | Cao | Cần xác định rõ chính sách dữ liệu trẻ em |
| Cognitive overload | Trung bình | 6 giai đoạn có quá nhiều với trẻ 6–8 tuổi? |

---

## 12. Kiến trúc kỹ thuật

### Tech Stack

**Frontend:** React + TypeScript (web)
- Vite — build tooling
- TanStack Query — server state management
- Tailwind CSS — styling
- React Router — navigation

**Backend — Hybrid Architecture:**
```
Java (Spring Boot)          Python (FastAPI)
────────────────────        ────────────────────
API Gateway                 Adaptive Engine
User Service                  - Scoring Function
Session Service               - Spaced Repetition
Content Service               - Entry Point Selector
Auth / Billing                - ML Pipeline (Phase 3)
```

**Database:**
- PostgreSQL (self-hosted) — user data, session logs; chạy trên Railway/Render, full control, không vendor lock-in
- Neo4j Aura — knowledge graph
- Redis — cache, realtime state

**Infrastructure:**
- Railway / Render (giai đoạn đầu)
- Cloudflare CDN (media assets)
- S3-compatible storage

**AI/Content:**
- Claude API — draft content
- Internal CMS — review + publish workflow

### Lý do chọn Hybrid
- Java xử lý high-throughput traffic và business logic
- Python sở hữu ML ecosystem (scikit-learn, numpy) cần thiết khi Adaptive Engine tiến hóa sang Phase 3
- Hai service giao tiếp qua internal HTTP call

### Lý do chọn React web (không phải mobile app)
- Tiếp cận người dùng ngay qua browser, không cần cài app
- Dễ iterate nhanh hơn trong giai đoạn MVP
- React ecosystem trưởng thành, nhiều thư viện visualization cho knowledge graph

### Lý do chọn PostgreSQL self-hosted (không phải Supabase)
- Full control schema, không bị ràng buộc BaaS API
- Không tốn chi phí Supabase khi traffic tăng
- Tương thích hoàn toàn với Java (JDBC, Spring Data JPA) và Python (SQLAlchemy)

---

## 12. Bước tiếp theo đề xuất

1. **Xác định MVP scope** — lĩnh vực nào, độ tuổi nào ra mắt trước
2. **Prototype 5 session mẫu** — kiểm tra cấu trúc 6 giai đoạn với người dùng thật
3. **Thiết kế hệ thống nội dung** — cách tổ chức knowledge graph để tạo hàng nghìn session
4. **User testing onboarding** — đo tỷ lệ hoàn thành 5 bước
5. **Xây dựng kỹ thuật** — kiến trúc backend cho adaptive learning engine
