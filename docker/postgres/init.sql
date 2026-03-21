-- =============================================================================
-- PostgreSQL init script — chạy tự động khi container khởi tạo lần đầu
-- Tạo schema và các bảng cốt lõi
-- =============================================================================

-- Extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- users
-- =============================================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(100) NOT NULL UNIQUE,
    display_name    VARCHAR(50)  NOT NULL,
    password_hash   TEXT         NOT NULL,
    explorer_type   VARCHAR(20),                   -- nature | technology | history | creative
    age_group       VARCHAR(20),                   -- child_8_10 | teen_11_17 | adult_18_plus
    streak_days     INT          NOT NULL DEFAULT 0,
    total_sessions  INT          NOT NULL DEFAULT 0,
    is_premium      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- =============================================================================
-- knowledge_nodes
-- =============================================================================
CREATE TABLE IF NOT EXISTS knowledge_nodes (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(120) NOT NULL,
    hook            TEXT         NOT NULL,
    domain          VARCHAR(20)  NOT NULL,         -- nature | technology | history | creative
    age_group       VARCHAR(20)  NOT NULL DEFAULT 'all',
    difficulty      SMALLINT     NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5),
    curiosity_score SMALLINT     NOT NULL DEFAULT 5 CHECK (curiosity_score BETWEEN 1 AND 10),
    is_published    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kn_domain_published ON knowledge_nodes(domain, is_published);
CREATE INDEX IF NOT EXISTS idx_kn_curiosity        ON knowledge_nodes(curiosity_score DESC);

-- =============================================================================
-- sessions
-- =============================================================================
CREATE TABLE IF NOT EXISTS sessions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    knowledge_node_id   UUID        NOT NULL REFERENCES knowledge_nodes(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS'
                                    CHECK (status IN ('IN_PROGRESS','COMPLETED','ABANDONED')),
    score_earned        INT         NOT NULL DEFAULT 0,
    duration_seconds    INT,
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sessions_user        ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_node   ON sessions(user_id, knowledge_node_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_status ON sessions(user_id, status);

-- =============================================================================
-- Trigger: updated_at tự động trên bảng users
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- SEED DATA — Knowledge Nodes (12 nodes, 4 domains × 3 nodes mỗi domain)
-- UUIDs cố định để đồng bộ với Neo4j seed
-- =============================================================================

INSERT INTO knowledge_nodes (id, title, hook, domain, age_group, difficulty, curiosity_score, is_published) VALUES

-- ── Nature (🌿) ──────────────────────────────────────────────────────────────
('11111111-0000-0000-0000-000000000001',
 'Tại sao bướm phải trải qua biến thái hoàn toàn?',
 'Con sâu bướm tan chảy hoàn toàn thành "súp tế bào" bên trong kén — rồi tái cấu trúc thành sinh vật khác. Tại sao không đơn giản hơn?',
 'nature', 'child_8_10', 2, 9, TRUE),

('11111111-0000-0000-0000-000000000002',
 'Tại sao bầu trời có màu xanh mà hoàng hôn lại đỏ?',
 'Cùng một ánh sáng mặt trời. Cùng một bầu khí quyển. Nhưng ban ngày xanh, lúc hoàng hôn đỏ rực. Điều gì đang xảy ra?',
 'nature', 'teen_11_17', 3, 8, TRUE),

('11111111-0000-0000-0000-000000000003',
 'Cây cối giao tiếp với nhau qua đất như thế nào?',
 'Rừng có một mạng internet ngầm dưới đất. Cây mẹ gửi đường cho cây con. Cây bệnh được cây lân cận cảnh báo. Không có não, không có miệng — nhưng vẫn "nói chuyện".',
 'nature', 'adult_18_plus', 4, 10, TRUE),

-- ── Technology (⚡) ──────────────────────────────────────────────────────────
('22222222-0000-0000-0000-000000000001',
 'GPS biết bạn đang ở đâu chính xác đến từng mét bằng cách nào?',
 'Điện thoại bạn không có dây nối đến vệ tinh. Không có radar. Không có camera. Nhưng GPS biết chính xác bạn đang đứng ở đâu trên Trái Đất. Bí quyết là gì?',
 'technology', 'teen_11_17', 3, 9, TRUE),

('22222222-0000-0000-0000-000000000002',
 'Internet thực ra là gì — vật lý mà nói?',
 'Bạn xem video YouTube từ máy chủ ở Mỹ trong chưa đầy 1 giây. Dữ liệu đi qua đâu? Có dây cáp dưới đáy Thái Bình Dương không? Câu trả lời sẽ làm bạn ngạc nhiên.',
 'technology', 'child_8_10', 2, 8, TRUE),

('22222222-0000-0000-0000-000000000003',
 'Mã hóa hoạt động như thế nào — và tại sao ngay cả NSA cũng không crack được?',
 'Mỗi ngày bạn gửi tin nhắn qua WhatsApp, mua hàng online, đăng nhập ngân hàng. Tất cả đều được mã hóa. Nhưng mã hóa "thực ra" là gì? Tại sao nó an toàn đến vậy?',
 'technology', 'adult_18_plus', 5, 9, TRUE),

-- ── History (🏛️) ─────────────────────────────────────────────────────────────
('33333333-0000-0000-0000-000000000001',
 'Kim tự tháp được xây thế nào khi chưa có máy móc hiện đại?',
 '2,3 triệu khối đá, mỗi khối nặng trung bình 2,5 tấn. Không có cần cẩu, không có xe tải — nhưng kim tự tháp vẫn chính xác đến từng cm. Bí ẩn lớn nhất lịch sử nhân loại.',
 'history', 'child_8_10', 2, 9, TRUE),

('33333333-0000-0000-0000-000000000002',
 'Thư viện Alexandria thực sự bị phá hủy như thế nào?',
 'Người ta nói Julius Caesar đốt nó. Người khác đổ lỗi cho người Arab. Thực ra, không ai đốt cả — nó "chết" theo cách đáng sợ hơn nhiều.',
 'history', 'teen_11_17', 3, 8, TRUE),

('33333333-0000-0000-0000-000000000003',
 'Con đường Tơ Lụa đã thay đổi thế giới như thế nào?',
 'Không chỉ là lụa và gia vị. Con đường Tơ Lụa mang theo bệnh dịch hạch, toán học Ả Rập, giấy từ Trung Quốc và tôn giáo — tái định hình nền văn minh nhân loại.',
 'history', 'adult_18_plus', 4, 8, TRUE),

-- ── Creative (🎨) ────────────────────────────────────────────────────────────
('44444444-0000-0000-0000-000000000001',
 'Tại sao âm nhạc làm chúng ta rùng mình và khóc?',
 'Một đoạn nhạc làm bạn nổi da gà mà không biết tại sao. Não bộ phản ứng với âm nhạc giống như với thức ăn và tình yêu — nhưng âm nhạc không cần thiết cho sự sống còn. Vậy tại sao?',
 'creative', 'teen_11_17', 3, 10, TRUE),

('44444444-0000-0000-0000-000000000002',
 'Màu sắc trộn lẫn: tại sao máy in dùng CMYK còn màn hình dùng RGB?',
 'Trộn sơn xanh và vàng ra xanh lá. Nhưng trộn ánh sáng xanh và vàng lại ra màu trắng. Cùng là "trộn màu" nhưng kết quả ngược nhau — tại sao?',
 'creative', 'child_8_10', 2, 7, TRUE),

('44444444-0000-0000-0000-000000000003',
 'Khoa học của storytelling: tại sao não người bị cuốn vào câu chuyện?',
 'Khi nghe số liệu, não xử lý 2 vùng. Khi nghe câu chuyện, 7 vùng não hoạt động — kể cả vùng vận động và khứu giác. Não không phân biệt được "trải nghiệm thật" và "câu chuyện hay".',
 'creative', 'adult_18_plus', 4, 9, TRUE)

ON CONFLICT (id) DO NOTHING;

