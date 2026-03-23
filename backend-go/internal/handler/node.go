package handler

import (
	"net/http"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/middleware"
	"github.com/aiwisdombattle/backend/internal/service"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type NodeHandler struct {
	nodeSvc    *service.NodeService
	sessionSvc *service.SessionService
}

func NewNodeHandler(nodeSvc *service.NodeService, sessionSvc *service.SessionService) *NodeHandler {
	return &NodeHandler{nodeSvc: nodeSvc, sessionSvc: sessionSvc}
}

// GET /api/v1/nodes?domain=optional
func (h *NodeHandler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		middleware.WriteError(w, r, domain.ErrUnauthorized)
		return
	}
	domainFilter := r.URL.Query().Get("domain")
	seenIDs, _ := h.sessionSvc.GetCompletedNodeIDs(r.Context(), userID)

	nodes, err := h.nodeSvc.GetPublished(r.Context(), domainFilter, seenIDs)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	if nodes == nil {
		nodes = []domain.KnowledgeNode{}
	}
	middleware.WriteJSON(w, http.StatusOK, nodes)
}

// GET /api/v1/nodes/:nodeId
func (h *NodeHandler) Get(w http.ResponseWriter, r *http.Request) {
	nodeID, err := uuid.Parse(chi.URLParam(r, "nodeId"))
	if err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	node, err := h.nodeSvc.GetByID(r.Context(), nodeID)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	resp := domain.KnowledgeNodeResponse{
		ID:              node.ID,
		Title:           node.Title,
		Domain:          node.Domain,
		AgeGroup:        node.AgeGroup,
		Difficulty:      node.Difficulty,
		CuriosityScore:  node.CuriosityScore,
		Hook:            node.Hook,
		GuessPrompt:     node.GuessPrompt,
		JourneySteps:    node.JourneySteps,
		RevealText:      node.RevealText,
		TeachBackPrompt: node.TeachBackPrompt,
		PayoffInsight:   node.PayoffInsight,
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}

// GET /api/v1/nodes/:nodeId/map
func (h *NodeHandler) Map(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		middleware.WriteError(w, r, domain.ErrUnauthorized)
		return
	}
	seenIDs, _ := h.sessionSvc.GetCompletedNodeIDs(r.Context(), userID)
	summaries, err := h.nodeSvc.GetKnowledgeMap(r.Context(), seenIDs)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	if summaries == nil {
		summaries = []domain.NodeSummary{}
	}
	middleware.WriteJSON(w, http.StatusOK, summaries)
}

// GET /api/v1/nodes/:nodeId/deep-dive
func (h *NodeHandler) DeepDive(w http.ResponseWriter, r *http.Request) {
	nodeID, err := uuid.Parse(chi.URLParam(r, "nodeId"))
	if err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	summaries, err := h.nodeSvc.GetDeepDive(r.Context(), nodeID)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	if summaries == nil {
		summaries = []domain.NodeSummary{}
	}
	middleware.WriteJSON(w, http.StatusOK, summaries)
}

// GET /api/v1/nodes/:nodeId/cross-domain
func (h *NodeHandler) CrossDomain(w http.ResponseWriter, r *http.Request) {
	nodeID, err := uuid.Parse(chi.URLParam(r, "nodeId"))
	if err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	summaries, err := h.nodeSvc.GetCrossDomain(r.Context(), nodeID)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	if summaries == nil {
		summaries = []domain.NodeSummary{}
	}
	middleware.WriteJSON(w, http.StatusOK, summaries)
}
