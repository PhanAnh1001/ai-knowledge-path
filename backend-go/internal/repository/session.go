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

type SessionRepository struct {
	db *pgxpool.Pool
}

func NewSessionRepository(db *pgxpool.Pool) *SessionRepository {
	return &SessionRepository{db: db}
}

func (r *SessionRepository) Create(ctx context.Context, s *domain.Session) error {
	const q = `
		INSERT INTO sessions (user_id, knowledge_node_id, status)
		VALUES ($1, $2, 'in_progress')
		RETURNING id, started_at, created_at, updated_at`
	return r.db.QueryRow(ctx, q, s.UserID, s.KnowledgeNodeID).
		Scan(&s.ID, &s.StartedAt, &s.CreatedAt, &s.UpdatedAt)
}

func (r *SessionRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Session, error) {
	const q = `
		SELECT id, user_id, knowledge_node_id, status, score, duration_seconds,
		       started_at, completed_at, created_at, updated_at
		FROM sessions WHERE id = $1`
	s := &domain.Session{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&s.ID, &s.UserID, &s.KnowledgeNodeID, &s.Status, &s.Score, &s.DurationSeconds,
		&s.StartedAt, &s.CompletedAt, &s.CreatedAt, &s.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return s, err
}

// FindInProgressByUserAndNode returns an existing in_progress session for (user, node) if any.
func (r *SessionRepository) FindInProgressByUserAndNode(ctx context.Context, userID, nodeID uuid.UUID) (*domain.Session, error) {
	const q = `
		SELECT id, user_id, knowledge_node_id, status, score, duration_seconds,
		       started_at, completed_at, created_at, updated_at
		FROM sessions
		WHERE user_id = $1 AND knowledge_node_id = $2 AND status = 'in_progress'
		ORDER BY started_at DESC LIMIT 1`
	s := &domain.Session{}
	err := r.db.QueryRow(ctx, q, userID, nodeID).Scan(
		&s.ID, &s.UserID, &s.KnowledgeNodeID, &s.Status, &s.Score, &s.DurationSeconds,
		&s.StartedAt, &s.CompletedAt, &s.CreatedAt, &s.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return s, err
}

// Complete marks the session as completed with the given score and duration.
func (r *SessionRepository) Complete(ctx context.Context, id uuid.UUID, score, durationSeconds int) error {
	now := time.Now()
	_, err := r.db.Exec(ctx,
		`UPDATE sessions SET status='completed', score=$2, duration_seconds=$3, completed_at=$4
		 WHERE id = $1`,
		id, score, durationSeconds, now,
	)
	return err
}

// FindCompletedNodeIDs returns IDs of nodes the user has completed at least once.
func (r *SessionRepository) FindCompletedNodeIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	const q = `
		SELECT DISTINCT knowledge_node_id FROM sessions
		WHERE user_id = $1 AND status = 'completed'`
	rows, err := r.db.Query(ctx, q, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}
