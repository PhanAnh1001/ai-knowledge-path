-- V3: Tạo bảng sessions
CREATE TABLE sessions (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL,
    knowledge_node_id   UUID        NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    score_earned        INT         NOT NULL DEFAULT 0,
    duration_seconds    INT,
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,

    CONSTRAINT pk_sessions               PRIMARY KEY (id),
    CONSTRAINT fk_sessions_user          FOREIGN KEY (user_id)           REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_sessions_node          FOREIGN KEY (knowledge_node_id) REFERENCES knowledge_nodes (id) ON DELETE CASCADE,
    CONSTRAINT chk_sessions_status       CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'ABANDONED'))
);

CREATE INDEX idx_sessions_user_id    ON sessions (user_id);
CREATE INDEX idx_sessions_node_id    ON sessions (knowledge_node_id);
CREATE INDEX idx_sessions_status     ON sessions (status);
