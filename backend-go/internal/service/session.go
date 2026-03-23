package service

import (
	"context"
	"fmt"
	"time"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/repository"
	"github.com/aiwisdombattle/backend/pkg/sm2"
	"github.com/google/uuid"
)

type SessionService struct {
	sessions  *repository.SessionRepository
	nodes     *repository.NodeRepository
	users     *repository.UserRepository
	progress  *repository.ProgressRepository
}

func NewSessionService(
	sessions *repository.SessionRepository,
	nodes *repository.NodeRepository,
	users *repository.UserRepository,
	progress *repository.ProgressRepository,
) *SessionService {
	return &SessionService{
		sessions: sessions,
		nodes:    nodes,
		users:    users,
		progress: progress,
	}
}

// StartSession reuses an existing in_progress session or creates a new one.
func (s *SessionService) StartSession(ctx context.Context, userID uuid.UUID, req domain.StartSessionRequest) (*domain.SessionStartResponse, error) {
	// Check node exists
	node, err := s.nodes.FindByID(ctx, req.NodeID)
	if err != nil {
		return nil, domain.ErrNotFound
	}

	// Reuse in_progress session if any
	sess, err := s.sessions.FindInProgressByUserAndNode(ctx, userID, req.NodeID)
	if err == domain.ErrNotFound {
		// Create new session
		sess = &domain.Session{UserID: userID, KnowledgeNodeID: req.NodeID}
		if err := s.sessions.Create(ctx, sess); err != nil {
			return nil, fmt.Errorf("create session: %w", err)
		}
	} else if err != nil {
		return nil, fmt.Errorf("find session: %w", err)
	}

	return &domain.SessionStartResponse{
		SessionID: sess.ID,
		Node:      nodeToResponse(node),
	}, nil
}

// CompleteSession marks a session as completed, updates SM-2, and returns next suggestions.
func (s *SessionService) CompleteSession(ctx context.Context, userID uuid.UUID, req domain.CompleteSessionRequest) (*domain.SessionCompleteResponse, error) {
	sess, err := s.sessions.FindByID(ctx, req.SessionID)
	if err != nil {
		return nil, domain.ErrNotFound
	}
	if sess.UserID != userID {
		return nil, domain.ErrForbidden
	}

	// Mark session complete
	if err := s.sessions.Complete(ctx, sess.ID, req.Score, req.DurationSeconds); err != nil {
		return nil, fmt.Errorf("complete session: %w", err)
	}

	// Get node difficulty for adaptive scoring
	node, err := s.nodes.FindByID(ctx, sess.KnowledgeNodeID)
	if err != nil {
		return nil, fmt.Errorf("find node: %w", err)
	}

	// Compute adaptive score (merged from Python engine)
	adaptiveScore := sm2.AdaptiveScore(req.Score, req.DurationSeconds, node.Difficulty)

	// Update SM-2 spaced repetition
	if err := s.updateSpacedRepetition(ctx, userID, node.ID, req.Score, node.Difficulty); err != nil {
		// Non-fatal — log and continue
		_ = err
	}

	// Increment user total sessions
	_ = s.users.IncrementTotalSessions(ctx, userID)

	// Get next suggestions
	seenIDs, _ := s.sessions.FindCompletedNodeIDs(ctx, userID)
	suggestions, err := s.nodes.FindNextSuggestions(ctx, sess.KnowledgeNodeID, seenIDs)
	if err != nil {
		suggestions = []domain.NodeSummary{}
	}
	if suggestions == nil {
		suggestions = []domain.NodeSummary{}
	}

	return &domain.SessionCompleteResponse{
		SessionID:       sess.ID,
		Score:           req.Score,
		AdaptiveScore:   adaptiveScore,
		NextSuggestions: suggestions,
	}, nil
}

// GetCompletedNodeIDs returns node IDs the user has completed.
func (s *SessionService) GetCompletedNodeIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	return s.sessions.FindCompletedNodeIDs(ctx, userID)
}

// ─── private ─────────────────────────────────────────────────────────────────

func (s *SessionService) updateSpacedRepetition(ctx context.Context, userID, nodeID uuid.UUID, score, difficulty int) error {
	quality := sm2.QualityFromScore(score)

	// Load existing progress or use defaults
	prog, err := s.progress.FindByUserAndNode(ctx, userID, nodeID)
	if err == domain.ErrNotFound {
		prog = &domain.UserNodeProgress{
			UserID:         userID,
			NodeID:         nodeID,
			SM2Repetitions: 0,
			SM2Easiness:    2.5,
			SM2Interval:    1,
		}
	} else if err != nil {
		return err
	}

	result := sm2.Calculate(quality, prog.SM2Repetitions, prog.SM2Easiness, prog.SM2Interval)

	nextReview := result.NextReviewDate
	lastReviewed := time.Now()

	prog.SM2Repetitions = result.NewRepetitions
	prog.SM2Easiness = result.NewEasiness
	prog.SM2Interval = result.NextInterval
	prog.NextReviewDate = &nextReview
	prog.LastReviewedAt = &lastReviewed

	return s.progress.Upsert(ctx, prog)
}

func nodeToResponse(n *domain.KnowledgeNode) domain.KnowledgeNodeResponse {
	return domain.KnowledgeNodeResponse{
		ID:              n.ID,
		Title:           n.Title,
		Domain:          n.Domain,
		AgeGroup:        n.AgeGroup,
		Difficulty:      n.Difficulty,
		CuriosityScore:  n.CuriosityScore,
		Hook:            n.Hook,
		GuessPrompt:     n.GuessPrompt,
		JourneySteps:    n.JourneySteps,
		RevealText:      n.RevealText,
		TeachBackPrompt: n.TeachBackPrompt,
		PayoffInsight:   n.PayoffInsight,
	}
}
