package domain

import (
	"time"

	"github.com/google/uuid"
)

type KnowledgeNode struct {
	ID              uuid.UUID `json:"id"`
	Title           string    `json:"title"`
	Domain          string    `json:"domain"`
	AgeGroup        string    `json:"ageGroup"`
	Difficulty      int       `json:"difficulty"`
	CuriosityScore  int       `json:"curiosityScore"`
	IsPublished     bool      `json:"isPublished"`
	Hook            string    `json:"hook"`
	GuessPrompt     string    `json:"guessPrompt"`
	JourneySteps    string    `json:"journeySteps"` // raw JSON string
	RevealText      string    `json:"revealText"`
	TeachBackPrompt string    `json:"teachBackPrompt"`
	PayoffInsight   string    `json:"payoffInsight"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
}

// NodeRelation represents a graph edge stored in node_relations table.
type NodeRelation struct {
	ID           uuid.UUID `json:"id"`
	FromNodeID   uuid.UUID `json:"fromNodeId"`
	ToNodeID     uuid.UUID `json:"toNodeId"`
	RelationType string    `json:"relationType"` // LEADS_TO | DEEP_DIVE | CROSS_DOMAIN
	Weight       float64   `json:"weight"`
	RelationVi   string    `json:"relationVi,omitempty"`
	Concept      string    `json:"concept,omitempty"`
	InsightVi    string    `json:"insightVi,omitempty"`
}

// NodeSummary is a lightweight node representation used in map/suggestions.
type NodeSummary struct {
	ID             uuid.UUID `json:"id"`
	Title          string    `json:"title"`
	Domain         string    `json:"domain"`
	AgeGroup       string    `json:"ageGroup"`
	Difficulty     int       `json:"difficulty"`
	CuriosityScore int       `json:"curiosityScore"`
	IsPublished    bool      `json:"isPublished"`
	// Relation info (for map/suggestions context)
	RelationType string  `json:"relationType,omitempty"`
	RelationVi   string  `json:"relationVi,omitempty"`
	Concept      string  `json:"concept,omitempty"`
	InsightVi    string  `json:"insightVi,omitempty"`
	Weight       float64 `json:"weight,omitempty"`
}

// KnowledgeNodeResponse is the full 6-stage response returned to clients.
type KnowledgeNodeResponse struct {
	ID              uuid.UUID `json:"id"`
	Title           string    `json:"title"`
	Domain          string    `json:"domain"`
	AgeGroup        string    `json:"ageGroup"`
	Difficulty      int       `json:"difficulty"`
	CuriosityScore  int       `json:"curiosityScore"`
	Hook            string    `json:"hook"`
	GuessPrompt     string    `json:"guessPrompt"`
	JourneySteps    string    `json:"journeySteps"`
	RevealText      string    `json:"revealText"`
	TeachBackPrompt string    `json:"teachBackPrompt"`
	PayoffInsight   string    `json:"payoffInsight"`
}
