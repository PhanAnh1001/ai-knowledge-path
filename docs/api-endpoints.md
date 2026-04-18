# API Endpoints — AI Knowledge Path

**Base URL:** `/api/v1`
**Auth:** JWT Bearer token (header `Authorization: Bearer <token>`)
**Content-Type:** `application/json`

---

## Conventions

- **200** — OK
- **201** — Created
- **204** — No Content
- **400** — Bad Request (validation)
- **401** — Unauthorized (missing/invalid token)
- **403** — Forbidden (không đủ quyền)
- **404** — Not Found
- **409** — Conflict (duplicate)
- **429** — Too Many Requests (quota)

Tất cả response lỗi trả về:
```json
{ "error": "MESSAGE", "code": "ERROR_CODE" }
```

---

## 1. Auth

### `POST /auth/register`
Đăng ký tài khoản mới.

**Request**
```json
{
  "email": "user@example.com",
  "password": "min8chars"
}
```

**Response `201`**
```json
{
  "access_token": "<jwt>",
  "refresh_token": "<jwt>",
  "user": { "id": "uuid", "email": "user@example.com" }
}
```

---

### `POST /auth/login`
Đăng nhập.

**Request**
```json
{ "email": "user@example.com", "password": "..." }
```

**Response `200`**
```json
{
  "access_token": "<jwt>",
  "refresh_token": "<jwt>",
  "user": { "id": "uuid", "email": "..." }
}
```

---

### `POST /auth/refresh`
Làm mới access token.

**Request**
```json
{ "refresh_token": "<jwt>" }
```

**Response `200`**
```json
{ "access_token": "<jwt>" }
```

---

### `POST /auth/logout`
Thu hồi refresh token. `🔒 Auth required`

**Response `204`**

---

## 2. User Profile

### `GET /me`
Lấy thông tin user hiện tại (profile + subscription). `🔒`

**Response `200`**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "profile": {
    "display_name": "Minh",
    "avatar_id": "avatar_fox",
    "explorer_type": "nature",
    "age_group": "child_8_10",
    "best_time": "evening",
    "onboarding_done": true
  },
  "subscription": {
    "plan": "free",
    "status": "active",
    "expires_at": null
  }
}
```

---

### `PUT /me/profile`
Cập nhật profile. `🔒`

**Request** (tất cả fields optional)
```json
{
  "display_name": "Minh",
  "avatar_id": "avatar_fox",
  "explorer_type": "nature",
  "age_group": "child_8_10",
  "best_time": "evening"
}
```

**Response `200`** — profile object đã cập nhật.

---

### `POST /me/onboarding`
Hoàn thành onboarding (5 bước). `🔒`

**Request**
```json
{
  "explorer_type": "nature",
  "best_time": "evening",
  "display_name": "Minh",
  "avatar_id": "avatar_fox"
}
```

**Response `200`**
```json
{
  "onboarding_done": true,
  "first_session_suggestion": {
    "node_id": "uuid",
    "hook": "Tại sao bạch tuộc có 3 trái tim?"
  }
}
```

---

## 3. Sessions

### `POST /sessions`
Tạo session mới. `🔒`

Adaptive Engine (Python) chọn `knowledge_node_id` và `entry_layer` phù hợp; Java service gọi nội bộ trước khi trả về.

**Request** (optional — nếu không gửi thì engine tự chọn)
```json
{ "node_id": "uuid" }
```

**Response `201`**
```json
{
  "session_id": "uuid",
  "node": {
    "id": "uuid",
    "title": "Tại sao bạch tuộc có 3 trái tim?",
    "domain": "nature"
  },
  "entry_layer": "context_first",
  "phases": {
    "hook": {
      "content": "Bạch tuộc có 3 trái tim — 2 tim bơm máu qua mang, 1 tim bơm đi toàn thân. Vậy chúng dừng tim khi bơi được không?"
    }
  },
  "quota": {
    "used": 1,
    "limit": 3,
    "reset_at": "2026-03-22T00:00:00Z"
  }
}
```

**Error `429`** — Free user đã dùng hết 3 session/ngày.
```json
{ "error": "Daily quota exceeded", "code": "QUOTA_EXCEEDED", "reset_at": "2026-03-22T00:00:00Z" }
```

---

### `GET /sessions/:id`
Lấy chi tiết một session. `🔒`

**Response `200`**
```json
{
  "session_id": "uuid",
  "status": "in_progress",
  "current_phase": "journey",
  "node": { "id": "uuid", "title": "..." },
  "started_at": "2026-03-21T10:00:00Z",
  "phases_completed": ["hook", "guess"]
}
```

---

### `PATCH /sessions/:id/phase`
Cập nhật tiến trình phase (gọi mỗi khi user hoàn thành 1 bước). `🔒`

**Request**
```json
{
  "phase": "guess",
  "phase_data": {
    "guess_text": "Vì tim cần nghỉ ngơi giữa các nhịp đập mạnh"
  }
}
```

**Response `200`**
```json
{
  "phase_completed": "guess",
  "next_phase": "journey",
  "next_phase_content": {
    "screens": [
      { "index": 1, "text": "Khi bơi, tim hệ thống của bạch tuộc thực sự ngừng đập..." },
      { "index": 2, "text": "Đó là lý do bạch tuộc ưa bò hơn bơi..." }
    ]
  }
}
```

---

### `POST /sessions/:id/complete`
Kết thúc session (sau phase `payoff`). `🔒`

**Request**
```json
{
  "teach_it_back_text": "Bạch tuộc có 3 tim vì máu của chúng không chứa hemoglobin..."
}
```

**Response `200`**
```json
{
  "score": 87,
  "ai_feedback": "Giải thích rất tốt! Bạn đã nắm được điểm chính về hemocyanin.",
  "identity_unlocked": {
    "label": "Nhà sinh vật học tò mò",
    "domain": "nature",
    "is_new": true
  },
  "suggested_next": [
    { "node_id": "uuid", "title": "Tại sao mực có thể thay đổi màu sắc?" },
    { "node_id": "uuid", "title": "Cá có ngủ không?" },
    { "node_id": "uuid", "title": "Tại sao san hô bị tẩy trắng?" }
  ],
  "graph_unlocked_count": 3
}
```

---

### `GET /sessions`
Lịch sử sessions của user. `🔒`

**Query params:** `?page=1&limit=20&status=completed`

**Response `200`**
```json
{
  "data": [
    {
      "session_id": "uuid",
      "node_title": "Tại sao bạch tuộc có 3 trái tim?",
      "status": "completed",
      "score": 87,
      "duration_seconds": 342,
      "completed_at": "2026-03-21T10:06:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

---

## 4. Knowledge Graph

### `GET /knowledge/nodes`
Danh sách nodes (có filter). `🔒`

**Query params:** `?domain=nature&page=1&limit=20`

**Response `200`**
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Tại sao bạch tuộc có 3 trái tim?",
      "domain": "nature",
      "difficulty": 2,
      "user_progress": {
        "seen": true,
        "next_review_at": "2026-03-28"
      }
    }
  ],
  "total": 150
}
```

---

### `GET /knowledge/nodes/:id`
Chi tiết một node + danh sách liên kết. `🔒`

**Response `200`**
```json
{
  "id": "uuid",
  "title": "Tại sao bạch tuộc có 3 trái tim?",
  "domain": "nature",
  "difficulty": 2,
  "connected_nodes": [
    { "id": "uuid", "title": "Tại sao mực có thể thay đổi màu sắc?", "relation": "same_family" },
    { "id": "uuid", "title": "Hemoglobin vs Hemocyanin", "relation": "deep_dive" }
  ],
  "user_progress": {
    "repetitions": 1,
    "ease_factor": 2.5,
    "next_review_at": "2026-03-28"
  }
}
```

---

### `GET /knowledge/graph`
Subgraph knowledge map của user (cho visualization). `🔒`

**Query params:** `?depth=2&center_node_id=uuid`

**Response `200`**
```json
{
  "nodes": [
    { "id": "uuid", "title": "...", "domain": "nature", "seen": true }
  ],
  "edges": [
    { "source": "uuid", "target": "uuid", "relation": "leads_to" }
  ]
}
```

---

## 5. Progress & Spaced Repetition

### `GET /me/progress`
Tổng quan tiến độ học. `🔒`

**Response `200`**
```json
{
  "total_sessions": 42,
  "nodes_explored": 18,
  "identities": [
    { "label": "Nhà sinh vật học tò mò", "domain": "nature", "unlocked_at": "2026-03-21" }
  ],
  "due_for_review": 3,
  "streak_days": 0,
  "domains": {
    "nature": { "explored": 10, "total": 50 },
    "technology": { "explored": 5, "total": 40 },
    "history": { "explored": 2, "total": 35 },
    "creative": { "explored": 1, "total": 25 }
  }
}
```

---

### `GET /me/review`
Lấy danh sách nodes cần ôn tập hôm nay (SRS). `🔒`

**Response `200`**
```json
{
  "due_count": 3,
  "nodes": [
    {
      "node_id": "uuid",
      "title": "Tại sao bạch tuộc có 3 trái tim?",
      "last_reviewed_at": "2026-03-14",
      "interval_days": 7
    }
  ]
}
```

---

## 6. Subscription

### `GET /me/subscription`
Trạng thái gói hiện tại. `🔒`

**Response `200`**
```json
{
  "plan": "free",
  "status": "active",
  "expires_at": null,
  "quota": { "sessions_used_today": 1, "sessions_limit": 3 }
}
```

---

### `POST /subscriptions/upgrade`
Khởi tạo luồng nâng cấp (trả về payment URL). `🔒`

**Request**
```json
{ "plan": "premium", "billing_cycle": "monthly" }
```

**Response `200`**
```json
{
  "payment_url": "https://...",
  "order_id": "uuid",
  "expires_in_seconds": 900
}
```

---

### `POST /subscriptions/webhook`
Callback từ payment provider (Stripe / MoMo). **Không cần Auth — xác thực bằng signature.**

**Headers:** `X-Signature: <hmac>`

**Response `200`**

---

## 7. Family Plan

### `GET /me/family`
Danh sách child profiles. `🔒` (chỉ parent)

**Response `200`**
```json
{
  "children": [
    {
      "user_id": "uuid",
      "display_name": "Minh",
      "avatar_id": "avatar_fox",
      "sessions_today": 2,
      "nodes_explored": 7,
      "last_active_at": "2026-03-21T15:00:00Z"
    }
  ]
}
```

---

### `POST /me/family/invite`
Tạo link mời child (tối đa 3 profiles). `🔒`

**Response `201`**
```json
{ "invite_token": "abc123", "expires_at": "2026-03-28T00:00:00Z" }
```

---

### `POST /me/family/join`
Child dùng invite token để kết nối. `🔒`

**Request**
```json
{ "invite_token": "abc123" }
```

**Response `200`**

---

### `GET /family/dashboard/:child_id`
Parent Dashboard — bản đồ học của con. `🔒` (chỉ parent)

**Response `200`**
```json
{
  "child": { "display_name": "Minh", "avatar_id": "avatar_fox" },
  "sessions_this_week": 12,
  "favorite_domain": "nature",
  "topics_explored": [
    { "node_id": "uuid", "title": "Bạch tuộc 3 tim", "completed_at": "2026-03-21" }
  ],
  "suggested_family_questions": [
    "Tại sao bạch tuộc thích bò hơn bơi?",
    "Con nghĩ hemocyanin khác hemoglobin ở điểm gì?"
  ]
}
```

---

## 8. Internal — Adaptive Engine (Java ↔ Python)

> Các endpoint này chỉ gọi nội bộ giữa Java service và Python Adaptive Engine. Không expose ra ngoài.

### `POST /internal/adaptive/suggest`
Java gọi Python để chọn session tiếp theo.

**Request**
```json
{
  "user_id": "uuid",
  "explorer_type": "nature",
  "best_time": "evening",
  "completed_node_ids": ["uuid1", "uuid2"],
  "due_review_node_ids": ["uuid3"]
}
```

**Response**
```json
{
  "node_id": "uuid",
  "entry_layer": "context_first",
  "reason": "high_curiosity_gap_score"
}
```

---

### `POST /internal/adaptive/score`
Java gọi Python để tính SM-2 score sau khi session hoàn thành.

**Request**
```json
{
  "user_id": "uuid",
  "node_id": "uuid",
  "teach_it_back_text": "...",
  "phase_durations": { "hook": 28, "guess": 40, "journey": 180 }
}
```

**Response**
```json
{
  "score": 87,
  "sm2_quality": 4,
  "ai_feedback": "Giải thích rất tốt!",
  "new_ease_factor": 2.6,
  "new_interval_days": 10
}
```
