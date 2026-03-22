-- Lưu trạng thái SM-2 (Spaced Repetition) của user với từng knowledge node
CREATE TABLE IF NOT EXISTS user_node_progress (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id           UUID        NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    sm2_repetitions   INTEGER     NOT NULL DEFAULT 0,
    sm2_easiness      DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    sm2_interval      INTEGER     NOT NULL DEFAULT 0,
    next_review_date  DATE,
    last_reviewed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uc_user_node_progress_user_node UNIQUE (user_id, node_id)
);

CREATE INDEX IF NOT EXISTS idx_unp_user_review
    ON user_node_progress (user_id, next_review_date);
