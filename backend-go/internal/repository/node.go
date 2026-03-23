package repository

import (
	"context"
	"errors"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type NodeRepository struct {
	db *pgxpool.Pool
}

func NewNodeRepository(db *pgxpool.Pool) *NodeRepository {
	return &NodeRepository{db: db}
}

const nodeColumns = `
	id, title, domain, age_group, difficulty, curiosity_score, is_published,
	COALESCE(hook,''), COALESCE(guess_prompt,''), COALESCE(journey_steps::text,'null'),
	COALESCE(reveal_text,''), COALESCE(teach_back_prompt,''), COALESCE(payoff_insight,''),
	created_at, updated_at`

func scanNode(row pgx.Row) (*domain.KnowledgeNode, error) {
	n := &domain.KnowledgeNode{}
	err := row.Scan(
		&n.ID, &n.Title, &n.Domain, &n.AgeGroup, &n.Difficulty, &n.CuriosityScore, &n.IsPublished,
		&n.Hook, &n.GuessPrompt, &n.JourneySteps,
		&n.RevealText, &n.TeachBackPrompt, &n.PayoffInsight,
		&n.CreatedAt, &n.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return n, err
}

func (r *NodeRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.KnowledgeNode, error) {
	q := `SELECT ` + nodeColumns + ` FROM knowledge_nodes WHERE id = $1`
	return scanNode(r.db.QueryRow(ctx, q, id))
}

func (r *NodeRepository) FindAllPublished(ctx context.Context) ([]domain.KnowledgeNode, error) {
	q := `SELECT ` + nodeColumns + ` FROM knowledge_nodes WHERE is_published = TRUE
		  ORDER BY curiosity_score DESC, difficulty ASC`
	return r.queryNodes(ctx, q)
}

func (r *NodeRepository) FindPublishedByDomain(ctx context.Context, domain_ string) ([]domain.KnowledgeNode, error) {
	q := `SELECT ` + nodeColumns + ` FROM knowledge_nodes
		  WHERE is_published = TRUE AND domain = $1
		  ORDER BY curiosity_score DESC, difficulty ASC`
	return r.queryNodes(ctx, q, domain_)
}

// FindUnseenByDomain returns published nodes in domain, excluding already-seen IDs.
func (r *NodeRepository) FindUnseenByDomain(ctx context.Context, domain_ string, seenIDs []uuid.UUID) ([]domain.KnowledgeNode, error) {
	q := `SELECT ` + nodeColumns + ` FROM knowledge_nodes
		  WHERE is_published = TRUE AND domain = $1 AND id != ALL($2)
		  ORDER BY curiosity_score DESC, difficulty ASC`
	return r.queryNodes(ctx, q, domain_, seenIDs)
}

// FindAllUnseen returns all published nodes, excluding already-seen IDs.
func (r *NodeRepository) FindAllUnseen(ctx context.Context, seenIDs []uuid.UUID) ([]domain.KnowledgeNode, error) {
	q := `SELECT ` + nodeColumns + ` FROM knowledge_nodes
		  WHERE is_published = TRUE AND id != ALL($1)
		  ORDER BY curiosity_score DESC, difficulty ASC`
	return r.queryNodes(ctx, q, seenIDs)
}

// FindNextSuggestions returns up to 3 LEADS_TO targets not yet seen.
func (r *NodeRepository) FindNextSuggestions(ctx context.Context, fromNodeID uuid.UUID, seenIDs []uuid.UUID) ([]domain.NodeSummary, error) {
	q := `
		SELECT n.id, n.title, n.domain, n.age_group, n.difficulty, n.curiosity_score, n.is_published,
		       nr.relation_type, COALESCE(nr.relation_vi,''), COALESCE(nr.concept,''),
		       COALESCE(nr.insight_vi,''), nr.weight
		FROM node_relations nr
		JOIN knowledge_nodes n ON n.id = nr.to_node_id
		WHERE nr.from_node_id = $1
		  AND nr.relation_type = 'LEADS_TO'
		  AND n.is_published = TRUE
		  AND n.id != ALL($2)
		ORDER BY nr.weight DESC
		LIMIT 3`
	return r.querySummaries(ctx, q, fromNodeID, seenIDs)
}

// FindKnowledgeMap returns nodes connected to any of the seenIDs via LEADS_TO or CROSS_DOMAIN.
func (r *NodeRepository) FindKnowledgeMap(ctx context.Context, seenIDs []uuid.UUID) ([]domain.NodeSummary, error) {
	q := `
		SELECT DISTINCT n.id, n.title, n.domain, n.age_group, n.difficulty, n.curiosity_score, n.is_published,
		       nr.relation_type, COALESCE(nr.relation_vi,''), COALESCE(nr.concept,''),
		       COALESCE(nr.insight_vi,''), nr.weight
		FROM node_relations nr
		JOIN knowledge_nodes n ON (n.id = nr.to_node_id OR n.id = nr.from_node_id)
		WHERE (nr.from_node_id = ANY($1) OR nr.to_node_id = ANY($1))
		  AND nr.relation_type IN ('LEADS_TO','CROSS_DOMAIN')
		  AND n.is_published = TRUE
		LIMIT 100`
	return r.querySummaries(ctx, q, seenIDs)
}

// FindDeepDiveChain returns nodes reachable via DEEP_DIVE (recursive, max depth 3).
func (r *NodeRepository) FindDeepDiveChain(ctx context.Context, nodeID uuid.UUID) ([]domain.NodeSummary, error) {
	q := `
		WITH RECURSIVE chain AS (
			SELECT to_node_id, 1 AS depth
			FROM node_relations
			WHERE from_node_id = $1 AND relation_type = 'DEEP_DIVE'
			UNION ALL
			SELECT nr.to_node_id, c.depth + 1
			FROM node_relations nr
			JOIN chain c ON nr.from_node_id = c.to_node_id
			WHERE nr.relation_type = 'DEEP_DIVE' AND c.depth < 3
		)
		SELECT DISTINCT n.id, n.title, n.domain, n.age_group, n.difficulty, n.curiosity_score, n.is_published,
		       'DEEP_DIVE' AS relation_type, '' AS relation_vi, '' AS concept, '' AS insight_vi, 1.0 AS weight
		FROM chain
		JOIN knowledge_nodes n ON n.id = chain.to_node_id
		WHERE n.is_published = TRUE
		ORDER BY n.difficulty ASC`
	return r.querySummaries(ctx, q, nodeID)
}

// FindCrossDomain returns up to 2 random CROSS_DOMAIN nodes from a different domain.
func (r *NodeRepository) FindCrossDomain(ctx context.Context, nodeID uuid.UUID) ([]domain.NodeSummary, error) {
	q := `
		SELECT n.id, n.title, n.domain, n.age_group, n.difficulty, n.curiosity_score, n.is_published,
		       nr.relation_type, COALESCE(nr.relation_vi,''), COALESCE(nr.concept,''),
		       COALESCE(nr.insight_vi,''), nr.weight
		FROM node_relations nr
		JOIN knowledge_nodes n ON n.id = nr.to_node_id
		JOIN knowledge_nodes src ON src.id = nr.from_node_id
		WHERE nr.from_node_id = $1
		  AND nr.relation_type = 'CROSS_DOMAIN'
		  AND n.domain <> src.domain
		  AND n.is_published = TRUE
		ORDER BY random()
		LIMIT 2`
	return r.querySummaries(ctx, q, nodeID)
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func (r *NodeRepository) queryNodes(ctx context.Context, q string, args ...any) ([]domain.KnowledgeNode, error) {
	rows, err := r.db.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var nodes []domain.KnowledgeNode
	for rows.Next() {
		n := domain.KnowledgeNode{}
		if err := rows.Scan(
			&n.ID, &n.Title, &n.Domain, &n.AgeGroup, &n.Difficulty, &n.CuriosityScore, &n.IsPublished,
			&n.Hook, &n.GuessPrompt, &n.JourneySteps,
			&n.RevealText, &n.TeachBackPrompt, &n.PayoffInsight,
			&n.CreatedAt, &n.UpdatedAt,
		); err != nil {
			return nil, err
		}
		nodes = append(nodes, n)
	}
	return nodes, rows.Err()
}

func (r *NodeRepository) querySummaries(ctx context.Context, q string, args ...any) ([]domain.NodeSummary, error) {
	rows, err := r.db.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var summaries []domain.NodeSummary
	for rows.Next() {
		s := domain.NodeSummary{}
		if err := rows.Scan(
			&s.ID, &s.Title, &s.Domain, &s.AgeGroup, &s.Difficulty, &s.CuriosityScore, &s.IsPublished,
			&s.RelationType, &s.RelationVi, &s.Concept, &s.InsightVi, &s.Weight,
		); err != nil {
			return nil, err
		}
		summaries = append(summaries, s)
	}
	return summaries, rows.Err()
}
