-- V1: Tạo bảng users
CREATE TABLE users (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    email           VARCHAR(100) NOT NULL,
    display_name    VARCHAR(50)  NOT NULL,
    password_hash   TEXT         NOT NULL,
    explorer_type   VARCHAR(20),
    age_group       VARCHAR(20),
    streak_days     INT          NOT NULL DEFAULT 0,
    total_sessions  INT          NOT NULL DEFAULT 0,
    is_premium      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE INDEX idx_users_email ON users (email);
