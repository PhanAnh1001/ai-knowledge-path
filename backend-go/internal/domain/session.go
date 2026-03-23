package domain

import (
	"time"

	"github.com/google/uuid"
)

type Session struct {
	ID              uuid.UUID  `json:"id"`
	UserID          uuid.UUID  `json:"userId"`
	KnowledgeNodeID uuid.UUID  `json:"knowledgeNodeId"`
	Status          string     `json:"status"` // in_progress | completed | abandoned
	Score           *int       `json:"score,omitempty"`
	DurationSeconds *int       `json:"durationSeconds,omitempty"`
	StartedAt       time.Time  `json:"startedAt"`
	CompletedAt     *time.Time `json:"completedAt,omitempty"`
	CreatedAt       time.Time  `json:"createdAt"`
	UpdatedAt       time.Time  `json:"updatedAt"`
}

type UserNodeProgress struct {
	ID              uuid.UUID  `json:"id"`
	UserID          uuid.UUID  `json:"userId"`
	NodeID          uuid.UUID  `json:"nodeId"`
	SM2Repetitions  int        `json:"sm2Repetitions"`
	SM2Easiness     float64    `json:"sm2Easiness"`
	SM2Interval     int        `json:"sm2Interval"`
	NextReviewDate  *time.Time `json:"nextReviewDate,omitempty"`
	LastReviewedAt  *time.Time `json:"lastReviewedAt,omitempty"`
	CreatedAt       time.Time  `json:"createdAt"`
	UpdatedAt       time.Time  `json:"updatedAt"`
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

type StartSessionRequest struct {
	NodeID uuid.UUID `json:"nodeId"`
}

type CompleteSessionRequest struct {
	SessionID       uuid.UUID `json:"sessionId"`
	Score           int       `json:"score"`
	DurationSeconds int       `json:"durationSeconds"`
}

// ── Response DTOs ─────────────────────────────────────────────────────────────

type SessionStartResponse struct {
	SessionID uuid.UUID             `json:"sessionId"`
	Node      KnowledgeNodeResponse `json:"node"`
}

type SessionCompleteResponse struct {
	SessionID       uuid.UUID     `json:"sessionId"`
	Score           int           `json:"score"`
	AdaptiveScore   float64       `json:"adaptiveScore"`
	NextSuggestions []NodeSummary `json:"nextSuggestions"`
}
