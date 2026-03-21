"""Unit tests cho Recommendation Service."""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.recommendation import RecommendationRequest
from app.services.recommendation_service import compute_recommendations

client = TestClient(app)

# Fixture nodes
NODES = [
    {"id": "node-nature-easy", "domain": "nature", "difficulty": 2, "curiosity_score": 6},
    {"id": "node-tech-medium", "domain": "technology", "difficulty": 3, "curiosity_score": 8},
    {"id": "node-history-hard", "domain": "history", "difficulty": 5, "curiosity_score": 9},
    {"id": "node-nature-review", "domain": "nature", "difficulty": 2, "curiosity_score": 5, "due_for_review": True},
]


def make_req(**kwargs):
    defaults = dict(
        user_id="user-1",
        explorer_type="nature",
        age_group="child_8_10",
        completed_node_ids=[],
        score_history=[],
        candidate_nodes=NODES,
        limit=3,
    )
    defaults.update(kwargs)
    return RecommendationRequest(**defaults)


def test_returns_requested_limit():
    result = compute_recommendations(make_req(limit=2))
    assert len(result.recommendations) <= 2


def test_review_node_gets_highest_priority():
    result = compute_recommendations(make_req())
    top = result.recommendations[0]
    assert top.node_id == "node-nature-review"
    assert top.reason == "due_for_review"


def test_completed_nodes_excluded():
    result = compute_recommendations(make_req(completed_node_ids=["node-tech-medium"]))
    ids = [r.node_id for r in result.recommendations]
    assert "node-tech-medium" not in ids


def test_completed_review_node_included():
    # Node đã hoàn thành nhưng đến hạn ôn → vẫn được gợi ý
    result = compute_recommendations(make_req(completed_node_ids=["node-nature-review"]))
    ids = [r.node_id for r in result.recommendations]
    assert "node-nature-review" in ids


def test_domain_match_preferred():
    # explorer_type=nature → node-nature-easy được ưu tiên hơn node cùng curiosity khác domain
    result = compute_recommendations(make_req(
        explorer_type="nature",
        candidate_nodes=[
            {"id": "node-a", "domain": "nature", "difficulty": 3, "curiosity_score": 7},
            {"id": "node-b", "domain": "history", "difficulty": 3, "curiosity_score": 7},
        ],
        limit=2,
    ))
    assert result.recommendations[0].node_id == "node-a"


def test_result_sorted_descending_by_priority():
    result = compute_recommendations(make_req())
    priorities = [r.priority for r in result.recommendations]
    assert priorities == sorted(priorities, reverse=True)


def test_api_endpoint_returns_200():
    resp = client.post("/recommendation", json={
        "user_id": "user-abc",
        "explorer_type": "technology",
        "age_group": "teen_11_17",
        "completed_node_ids": [],
        "score_history": [],
        "candidate_nodes": [
            {"id": "n1", "domain": "technology", "difficulty": 3, "curiosity_score": 8},
            {"id": "n2", "domain": "nature", "difficulty": 2, "curiosity_score": 6},
        ],
        "limit": 2,
    })
    assert resp.status_code == 200
    body = resp.json()
    assert body["user_id"] == "user-abc"
    assert len(body["recommendations"]) <= 2


def test_api_rejects_invalid_explorer_type():
    resp = client.post("/recommendation", json={
        "user_id": "user-abc",
        "explorer_type": "invalid_type",
        "age_group": "teen_11_17",
        "candidate_nodes": [],
    })
    assert resp.status_code == 422
