"""
Recommendation Service — chọn knowledge node tiếp theo phù hợp nhất với người dùng.

Thuật toán (Phase 1 — rule-based, không cần ML):

Priority score = w1 * review_score + w2 * curiosity_score + w3 * difficulty_score + w4 * domain_score

Trong đó:
    review_score    = 1.0 nếu node đến hạn ôn lại (spaced repetition), 0 nếu không
    curiosity_score = curiosity_score / 10 (chuẩn hóa về [0, 1])
    difficulty_score = 1.0 - |node_difficulty - ideal_difficulty| / 4  (penalty khi lệch)
    domain_score    = 1.0 nếu domain khớp explorerType của user, 0.5 nếu không
"""

from app.schemas.recommendation import RecommendationRequest, RecommendationResponse, RecommendedNode

# Trọng số
_W_REVIEW = 2.0
_W_CURIOSITY = 1.5
_W_DIFFICULTY = 1.0
_W_DOMAIN = 0.8

# Độ khó lý tưởng theo nhóm tuổi
_IDEAL_DIFFICULTY: dict[str, int] = {
    "child_8_10": 2,
    "teen_11_17": 3,
    "adult_18_plus": 4,
}

# Mapping explorerType → domain trong knowledge graph
_EXPLORER_DOMAIN: dict[str, str] = {
    "nature": "nature",
    "technology": "technology",
    "history": "history",
    "creative": "creative",
}


def _get_reason(
    review_score: float,
    curiosity_score_norm: float,
    difficulty_score: float,
    domain_score: float,
) -> str:
    if review_score > 0:
        return "due_for_review"
    if curiosity_score_norm >= 0.8:
        return "high_curiosity"
    if difficulty_score >= 0.8:
        return "difficulty_match"
    if domain_score == 1.0:
        return "domain_match"
    return "exploration"


def compute_recommendations(req: RecommendationRequest) -> RecommendationResponse:
    completed_set = set(req.completed_node_ids)
    ideal_difficulty = _IDEAL_DIFFICULTY.get(req.age_group, 3)
    preferred_domain = _EXPLORER_DOMAIN.get(req.explorer_type, req.explorer_type)

    # Tập các node đến hạn ôn (được đánh dấu từ Java service qua candidate_nodes)
    due_review_ids = {
        n["id"] for n in req.candidate_nodes if n.get("due_for_review", False)
    }

    recommendations: list[RecommendedNode] = []

    for node in req.candidate_nodes:
        node_id = node.get("id", "")

        # Bỏ qua node đã hoàn thành (trừ khi đến hạn ôn)
        if node_id in completed_set and node_id not in due_review_ids:
            continue

        # Tính từng thành phần điểm
        review_score = 1.0 if node_id in due_review_ids else 0.0

        raw_curiosity = float(node.get("curiosity_score", 5))
        curiosity_score_norm = min(raw_curiosity / 10.0, 1.0)

        node_difficulty = int(node.get("difficulty", 3))
        difficulty_score = 1.0 - abs(node_difficulty - ideal_difficulty) / 4.0

        node_domain = node.get("domain", "")
        domain_score = 1.0 if node_domain == preferred_domain else 0.5

        priority = (
            _W_REVIEW * review_score
            + _W_CURIOSITY * curiosity_score_norm
            + _W_DIFFICULTY * difficulty_score
            + _W_DOMAIN * domain_score
        )

        reason = _get_reason(review_score, curiosity_score_norm, difficulty_score, domain_score)

        recommendations.append(RecommendedNode(
            node_id=node_id,
            priority=round(priority, 4),
            reason=reason,
        ))

    # Sắp xếp giảm dần theo priority, lấy top `limit`
    recommendations.sort(key=lambda r: r.priority, reverse=True)
    recommendations = recommendations[: req.limit]

    return RecommendationResponse(
        user_id=req.user_id,
        recommendations=recommendations,
    )
