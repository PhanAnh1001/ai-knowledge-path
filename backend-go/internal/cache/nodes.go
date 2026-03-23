// Package cache provides an in-memory cache for knowledge nodes.
// TTL is 10 minutes; cache is invalidated on first miss after expiry.
package cache

import (
	"sync"
	"time"

	"github.com/aiwisdombattle/backend/internal/domain"
)

const defaultTTL = 10 * time.Minute

// NodeCache caches the full published node list in memory.
type NodeCache struct {
	mu       sync.RWMutex
	allNodes []domain.KnowledgeNode
	byDomain map[string][]domain.KnowledgeNode
	expiry   time.Time
	ttl      time.Duration
}

func NewNodeCache() *NodeCache {
	return &NodeCache{
		byDomain: make(map[string][]domain.KnowledgeNode),
		ttl:      defaultTTL,
	}
}

func (c *NodeCache) valid() bool {
	return time.Now().Before(c.expiry)
}

// GetAll returns cached node list (all domains) and true if the cache is warm.
func (c *NodeCache) GetAll() ([]domain.KnowledgeNode, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	if !c.valid() || c.allNodes == nil {
		return nil, false
	}
	return c.allNodes, true
}

// GetByDomain returns cached node list for a specific domain and true if warm.
func (c *NodeCache) GetByDomain(domain string) ([]domain.KnowledgeNode, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	if !c.valid() {
		return nil, false
	}
	nodes, ok := c.byDomain[domain]
	return nodes, ok
}

// SetAll stores all nodes and resets the TTL.
func (c *NodeCache) SetAll(nodes []domain.KnowledgeNode) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.allNodes = nodes
	// rebuild byDomain index
	c.byDomain = make(map[string][]domain.KnowledgeNode)
	for _, n := range nodes {
		c.byDomain[n.Domain] = append(c.byDomain[n.Domain], n)
	}
	c.expiry = time.Now().Add(c.ttl)
}

// Invalidate clears the cache immediately.
func (c *NodeCache) Invalidate() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.allNodes = nil
	c.byDomain = make(map[string][]domain.KnowledgeNode)
	c.expiry = time.Time{}
}
