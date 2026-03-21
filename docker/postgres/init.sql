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
