-- V2: Tạo bảng knowledge_nodes
CREATE TABLE knowledge_nodes (
    id              UUID         NOT NULL DEFAULT gen_random_uuid(),
    title           VARCHAR(120) NOT NULL,
    hook            TEXT         NOT NULL,
    domain          VARCHAR(20)  NOT NULL,
    age_group       VARCHAR(20)  NOT NULL DEFAULT 'all',
    difficulty      INT          NOT NULL DEFAULT 2,
    curiosity_score INT          NOT NULL DEFAULT 5,
    is_published    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_knowledge_nodes PRIMARY KEY (id),
    CONSTRAINT chk_difficulty CHECK (difficulty BETWEEN 1 AND 5),
    CONSTRAINT chk_curiosity  CHECK (curiosity_score BETWEEN 1 AND 10)
);

CREATE INDEX idx_knowledge_nodes_domain     ON knowledge_nodes (domain);
CREATE INDEX idx_knowledge_nodes_published  ON knowledge_nodes (is_published);
