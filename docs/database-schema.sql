-- =============================================================================
-- AI Knowledge Path — PostgreSQL Schema
-- Version: 1.0
-- =============================================================================
-- Conventions:
--   - UUID primary keys (uuid_generate_v4())
--   - snake_case column names
--   - created_at / updated_at trên mọi bảng
--   - ENUM types cho trạng thái cố định
--   - Indexes trên các cột JOIN và WHERE phổ biến
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE subscription_plan AS ENUM ('free', 'premium', 'family');
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'expired', 'trial');

CREATE TYPE explorer_type AS ENUM ('nature', 'technology', 'history', 'creative');
CREATE TYPE age_group AS ENUM ('child_8_10', 'teen_11_17', 'adult_18_plus');
CREATE TYPE best_time AS ENUM ('morning', 'evening', 'commute', 'anytime');

CREATE TYPE session_status AS ENUM ('in_progress', 'completed', 'abandoned');
CREATE TYPE session_phase AS ENUM (
    'hook',           -- ① THE HOOK
    'guess',          -- ② YOUR GUESS
    'journey',        -- ③ THE JOURNEY
    'reveal',         -- ④ THE REVEAL
    'teach_it_back',  -- ⑤ TEACH IT BACK
    'payoff'          -- ⑥ THE PAYOFF
);
CREATE TYPE entry_point_layer AS ENUM (
    'context_first',    -- Lớp 1: gắn với cuộc sống hiện tại
    'discovery_first',  -- Lớp 2: câu hỏi phản trực giác
    'story_first'       -- Lớp 3: câu chuyện đang dang dở
);

-- =============================================================================
-- USERS & AUTH
-- =============================================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           TEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- USER PROFILES
-- =============================================================================

CREATE TABLE user_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name    TEXT NOT NULL,
    avatar_id       TEXT,                          -- ID trỏ tới asset avatar
    explorer_type   explorer_type,                 -- chọn lúc onboarding
    age_group       age_group,
    best_time       best_time,                     -- thời điểm học tốt nhất
    onboarding_done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id)
);

-- =============================================================================
-- SUBSCRIPTIONS & BILLING
-- =============================================================================

CREATE TABLE subscriptions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan                subscription_plan NOT NULL DEFAULT 'free',
    status              subscription_status NOT NULL DEFAULT 'active',
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMPTZ,               -- NULL = free (không hết hạn)
    cancelled_at        TIMESTAMPTZ,
    payment_provider    TEXT,                      -- 'stripe', 'momo', etc.
    external_id         TEXT,                      -- ID từ payment provider
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status  ON subscriptions(status);

-- =============================================================================
-- FAMILY LINKS (Family Plan)
-- =============================================================================

-- Liên kết parent account → child profile
-- Một parent có thể có tối đa 3 child profiles (Family Plan)
CREATE TABLE family_links (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    child_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (parent_id, child_id)
);

CREATE INDEX idx_family_links_parent ON family_links(parent_id);

-- =============================================================================
-- KNOWLEDGE NODES (mirror từ Neo4j — dùng cho SQL query & reporting)
-- =============================================================================

-- Neo4j giữ cấu trúc graph. Bảng này lưu metadata để JOIN với session data.
CREATE TABLE knowledge_nodes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    neo4j_id        TEXT UNIQUE NOT NULL,          -- ID node trong Neo4j
    title           TEXT NOT NULL,
    domain          explorer_type NOT NULL,        -- nature / technology / history / creative
    difficulty      SMALLINT CHECK (difficulty BETWEEN 1 AND 5),
    is_published    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_knowledge_nodes_domain     ON knowledge_nodes(domain);
CREATE INDEX idx_knowledge_nodes_published  ON knowledge_nodes(is_published);

-- =============================================================================
-- SESSIONS
-- =============================================================================

CREATE TABLE sessions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    knowledge_node_id   UUID REFERENCES knowledge_nodes(id),
    entry_layer         entry_point_layer NOT NULL DEFAULT 'context_first',
    status              session_status NOT NULL DEFAULT 'in_progress',
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    duration_seconds    INTEGER,                   -- thời gian thực tế (giây)
    score               SMALLINT CHECK (score BETWEEN 0 AND 100),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id   ON sessions(user_id);
CREATE INDEX idx_sessions_status    ON sessions(status);
CREATE INDEX idx_sessions_started   ON sessions(started_at);

-- =============================================================================
-- SESSION PHASES (chi tiết từng bước trong session)
-- =============================================================================

CREATE TABLE session_phases (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id      UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    phase           session_phase NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    duration_seconds INTEGER,
    -- JSON linh hoạt cho dữ liệu riêng mỗi phase
    -- guess phase: { "guess_text": "..." }
    -- journey phase: { "screens_viewed": 3, "screens_total": 4 }
    -- teach_it_back phase: { "explanation": "...", "ai_feedback_score": 85 }
    phase_data      JSONB,
    UNIQUE (session_id, phase)
);

CREATE INDEX idx_session_phases_session ON session_phases(session_id);

-- =============================================================================
-- SESSION DAILY QUOTA (giới hạn 3 session/ngày cho Free tier)
-- =============================================================================

CREATE TABLE session_daily_quota (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quota_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    sessions_used   SMALLINT NOT NULL DEFAULT 0,
    UNIQUE (user_id, quota_date)
);

CREATE INDEX idx_quota_user_date ON session_daily_quota(user_id, quota_date);

-- =============================================================================
-- TOPIC PROGRESS (Spaced Repetition per user per knowledge node)
-- =============================================================================

-- Dùng thuật toán SM-2 (SuperMemo 2) cho Spaced Repetition
CREATE TABLE topic_progress (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    knowledge_node_id   UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    -- SM-2 fields
    repetitions         SMALLINT NOT NULL DEFAULT 0,   -- số lần đã ôn
    ease_factor         NUMERIC(4,2) NOT NULL DEFAULT 2.5, -- hệ số dễ/khó (1.3–2.5+)
    interval_days       INTEGER NOT NULL DEFAULT 1,    -- khoảng cách lần ôn tiếp
    next_review_at      DATE NOT NULL DEFAULT CURRENT_DATE,
    last_score          SMALLINT CHECK (last_score BETWEEN 0 AND 5), -- SM-2 quality score
    -- Metadata
    first_seen_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_reviewed_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, knowledge_node_id)
);

CREATE INDEX idx_topic_progress_user         ON topic_progress(user_id);
CREATE INDEX idx_topic_progress_next_review  ON topic_progress(user_id, next_review_at);

-- =============================================================================
-- USER IDENTITY (Identity-Based Progress — "Em có tư duy của nhà thiên văn học")
-- =============================================================================

CREATE TABLE user_identities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    identity_label  TEXT NOT NULL,             -- "Nhà thiên văn học", "Nhà sinh vật học"
    domain          explorer_type NOT NULL,
    unlocked_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, identity_label)
);

CREATE INDEX idx_user_identities_user ON user_identities(user_id);

-- =============================================================================
-- AUDIT / UPDATED_AT TRIGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Áp dụng trigger cho tất cả bảng có updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'updated_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_set_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            t
        );
    END LOOP;
END;
$$;
