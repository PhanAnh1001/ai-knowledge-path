-- Migration 001: Initial schema for Go backend
-- Replaces Java Spring Boot schema — merges user + user_profiles, removes neo4j_id

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Users (merged with profile) ────────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    display_name    TEXT NOT NULL,
    explorer_type   TEXT NOT NULL DEFAULT 'nature'
                        CHECK (explorer_type IN ('nature','technology','history','creative')),
    age_group       TEXT NOT NULL DEFAULT 'adult_18_plus'
                        CHECK (age_group IN ('child_8_10','teen_11_17','adult_18_plus')),
    streak_days     INTEGER NOT NULL DEFAULT 0,
    total_sessions  INTEGER NOT NULL DEFAULT 0,
    premium         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- ─── Knowledge Nodes (includes 6-stage content, no neo4j_id) ────────────────
CREATE TABLE knowledge_nodes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title               TEXT NOT NULL,
    domain              TEXT NOT NULL
                            CHECK (domain IN ('nature','technology','history','creative')),
    age_group           TEXT NOT NULL DEFAULT 'all',
    difficulty          SMALLINT NOT NULL DEFAULT 2
                            CHECK (difficulty BETWEEN 1 AND 5),
    curiosity_score     SMALLINT NOT NULL DEFAULT 5
                            CHECK (curiosity_score BETWEEN 1 AND 10),
    is_published        BOOLEAN NOT NULL DEFAULT FALSE,
    -- 6-stage content
    hook                TEXT,           -- ① THE HOOK
    guess_prompt        TEXT,           -- ② YOUR GUESS
    journey_steps       JSONB,          -- ③ THE JOURNEY  (JSON array of strings)
    reveal_text         TEXT,           -- ④ THE REVEAL
    teach_back_prompt   TEXT,           -- ⑤ TEACH IT BACK
    payoff_insight      TEXT,           -- ⑥ THE PAYOFF
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_knowledge_nodes_domain    ON knowledge_nodes(domain);
CREATE INDEX idx_knowledge_nodes_published ON knowledge_nodes(is_published);

-- ─── Sessions ────────────────────────────────────────────────────────────────
CREATE TABLE sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    knowledge_node_id   UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    status              TEXT NOT NULL DEFAULT 'in_progress'
                            CHECK (status IN ('in_progress','completed','abandoned')),
    score               SMALLINT CHECK (score BETWEEN 0 AND 100),
    duration_seconds    INTEGER,
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_status  ON sessions(status);

-- ─── User Node Progress (SM-2 Spaced Repetition) ─────────────────────────────
CREATE TABLE user_node_progress (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id             UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    sm2_repetitions     SMALLINT NOT NULL DEFAULT 0,
    sm2_easiness        DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    sm2_interval        INTEGER NOT NULL DEFAULT 1,
    next_review_date    DATE,
    last_reviewed_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, node_id)
);

CREATE INDEX idx_user_node_progress_user        ON user_node_progress(user_id);
CREATE INDEX idx_user_node_progress_next_review ON user_node_progress(user_id, next_review_date);

-- ─── updated_at trigger ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_knowledge_nodes_updated_at
    BEFORE UPDATE ON knowledge_nodes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sessions_updated_at
    BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_node_progress_updated_at
    BEFORE UPDATE ON user_node_progress
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
