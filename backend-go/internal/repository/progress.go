package repository

import (
	"context"
	"errors"
	"time"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ProgressRepository struct {
	db *pgxpool.Pool
}

func NewProgressRepository(db *pgxpool.Pool) *ProgressRepository {
	return &ProgressRepository{db: db}
}

func (r *ProgressRepository) FindByUserAndNode(ctx context.Context, userID, nodeID uuid.UUID) (*domain.UserNodeProgress, error) {
	const q = `
		SELECT id, user_id, node_id, sm2_repetitions, sm2_easiness, sm2_interval,
		       next_review_date, last_reviewed_at, created_at, updated_at
		FROM user_node_progress
		WHERE user_id = $1 AND node_id = $2`
	p := &domain.UserNodeProgress{}
	err := r.db.QueryRow(ctx, q, userID, nodeID).Scan(
		&p.ID, &p.UserID, &p.NodeID, &p.SM2Repetitions, &p.SM2Easiness, &p.SM2Interval,
		&p.NextReviewDate, &p.LastReviewedAt, &p.CreatedAt, &p.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return p, err
}

// Upsert creates or updates the SM-2 progress record for (user, node).
func (r *ProgressRepository) Upsert(ctx context.Context, p *domain.UserNodeProgress) error {
	now := time.Now()
	const q = `
		INSERT INTO user_node_progress
			(user_id, node_id, sm2_repetitions, sm2_easiness, sm2_interval, next_review_date, last_reviewed_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (user_id, node_id) DO UPDATE SET
			sm2_repetitions  = EXCLUDED.sm2_repetitions,
			sm2_easiness     = EXCLUDED.sm2_easiness,
			sm2_interval     = EXCLUDED.sm2_interval,
			next_review_date = EXCLUDED.next_review_date,
			last_reviewed_at = EXCLUDED.last_reviewed_at,
			updated_at       = NOW()
		RETURNING id, created_at, updated_at`
	return r.db.QueryRow(ctx, q,
		p.UserID, p.NodeID, p.SM2Repetitions, p.SM2Easiness, p.SM2Interval,
		p.NextReviewDate, now,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
}
