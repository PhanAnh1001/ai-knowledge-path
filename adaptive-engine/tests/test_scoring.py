"""Unit tests cho Scoring Service."""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.scoring import ScoreRequest
from app.services.scoring_service import compute_score

client = TestClient(app)


def test_perfect_score_easy_node():
    req = ScoreRequest(raw_score=100, duration_seconds=200, difficulty=1, hints_used=0, ideal_duration_seconds=300)
    result = compute_score(req)
    assert result.adaptive_score == 100.0
    assert result.difficulty_bonus == 1.0
    assert result.speed_bonus == 1.0
    assert result.hint_penalty == 0.0


def test_difficulty_bonus_increases_with_difficulty():
    base = ScoreRequest(raw_score=80, duration_seconds=300, difficulty=1, hints_used=0)
    hard = ScoreRequest(raw_score=80, duration_seconds=300, difficulty=5, hints_used=0)
    assert compute_score(hard).adaptive_score > compute_score(base).adaptive_score


def test_speed_penalty_applied_when_over_time():
    fast = ScoreRequest(raw_score=80, duration_seconds=100, difficulty=3, hints_used=0, ideal_duration_seconds=300)
    slow = ScoreRequest(raw_score=80, duration_seconds=600, difficulty=3, hints_used=0, ideal_duration_seconds=300)
    assert compute_score(fast).adaptive_score > compute_score(slow).adaptive_score


def test_hint_penalty_reduces_score():
    no_hint = ScoreRequest(raw_score=80, duration_seconds=300, difficulty=3, hints_used=0)
    with_hint = ScoreRequest(raw_score=80, duration_seconds=300, difficulty=3, hints_used=3)
    assert compute_score(no_hint).adaptive_score > compute_score(with_hint).adaptive_score


def test_adaptive_score_capped_at_100():
    req = ScoreRequest(raw_score=100, duration_seconds=10, difficulty=5, hints_used=0, ideal_duration_seconds=300)
    result = compute_score(req)
    assert result.adaptive_score <= 100.0


def test_api_endpoint_returns_200():
    resp = client.post("/scoring", json={
        "raw_score": 75,
        "duration_seconds": 280,
        "difficulty": 3,
        "hints_used": 1,
        "ideal_duration_seconds": 300,
    })
    assert resp.status_code == 200
    body = resp.json()
    assert "adaptive_score" in body
    assert "mastery_delta" in body
    assert "curiosity_boost" in body


def test_api_rejects_invalid_difficulty():
    resp = client.post("/scoring", json={
        "raw_score": 80,
        "duration_seconds": 300,
        "difficulty": 10,  # > 5, invalid
    })
    assert resp.status_code == 422
