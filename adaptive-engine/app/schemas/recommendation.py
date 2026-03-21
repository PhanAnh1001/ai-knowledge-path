from typing import Literal
from pydantic import BaseModel, Field


class NodeScore(BaseModel):
    node_id: str
    adaptive_score: float
    completed_at: str  # ISO 8601 datetime


class RecommendationRequest(BaseModel):
    user_id: str = Field(..., description="UUID người dùng")
    explorer_type: Literal["nature", "technology", "history", "creative"]
    age_group: Literal["child_8_10", "teen_11_17", "adult_18_plus"]
    completed_node_ids: list[str] = Field(default_factory=list)
    score_history: list[NodeScore] = Field(default_factory=list)
    candidate_nodes: list[dict] = Field(
        ...,
        description="Danh sách node candidate từ Java service [{id, domain, difficulty, curiosity_score, ...}]",
    )
    limit: int = Field(default=3, ge=1, le=10)


class RecommendedNode(BaseModel):
    node_id: str
    priority: float = Field(..., description="Điểm ưu tiên (cao hơn = gợi ý trước)")
    reason: Literal["due_for_review", "high_curiosity", "difficulty_match", "domain_match", "exploration"]


class RecommendationResponse(BaseModel):
    user_id: str
    recommendations: list[RecommendedNode]
