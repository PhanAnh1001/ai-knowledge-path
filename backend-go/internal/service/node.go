package service

import (
	"context"

	"github.com/aiwisdombattle/backend/internal/cache"
	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/repository"
	"github.com/google/uuid"
)

type NodeService struct {
	repo  *repository.NodeRepository
	cache *cache.NodeCache
}

func NewNodeService(repo *repository.NodeRepository, cache *cache.NodeCache) *NodeService {
	return &NodeService{repo: repo, cache: cache}
}

// GetPublished returns published nodes, optionally filtered by domain.
// Unseeen filtering is applied based on the user's completed session IDs.
func (s *NodeService) GetPublished(ctx context.Context, domainFilter string, seenIDs []uuid.UUID) ([]domain.KnowledgeNode, error) {
	// Try cache first
	if domainFilter != "" {
		if cached, ok := s.cache.GetByDomain(domainFilter); ok {
			return filterUnseen(cached, seenIDs), nil
		}
	} else {
		if cached, ok := s.cache.GetAll(); ok {
			return filterUnseen(cached, seenIDs), nil
		}
	}

	// Cache miss — load from DB
	var (
		nodes []domain.KnowledgeNode
		err   error
	)
	if domainFilter != "" {
		nodes, err = s.repo.FindPublishedByDomain(ctx, domainFilter)
	} else {
		nodes, err = s.repo.FindAllPublished(ctx)
	}
	if err != nil {
		return nil, err
	}

	// Warm cache with all published nodes if we loaded them all
	if domainFilter == "" {
		s.cache.SetAll(nodes)
	}

	return filterUnseen(nodes, seenIDs), nil
}

func (s *NodeService) GetByID(ctx context.Context, id uuid.UUID) (*domain.KnowledgeNode, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *NodeService) GetKnowledgeMap(ctx context.Context, seenIDs []uuid.UUID) ([]domain.NodeSummary, error) {
	if len(seenIDs) == 0 {
		return []domain.NodeSummary{}, nil
	}
	return s.repo.FindKnowledgeMap(ctx, seenIDs)
}

func (s *NodeService) GetDeepDive(ctx context.Context, nodeID uuid.UUID) ([]domain.NodeSummary, error) {
	return s.repo.FindDeepDiveChain(ctx, nodeID)
}

func (s *NodeService) GetCrossDomain(ctx context.Context, nodeID uuid.UUID) ([]domain.NodeSummary, error) {
	return s.repo.FindCrossDomain(ctx, nodeID)
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func filterUnseen(nodes []domain.KnowledgeNode, seenIDs []uuid.UUID) []domain.KnowledgeNode {
	if len(seenIDs) == 0 {
		return nodes
	}
	seenSet := make(map[uuid.UUID]struct{}, len(seenIDs))
	for _, id := range seenIDs {
		seenSet[id] = struct{}{}
	}
	var result []domain.KnowledgeNode
	for _, n := range nodes {
		if _, seen := seenSet[n.ID]; !seen {
			result = append(result, n)
		}
	}
	return result
}
