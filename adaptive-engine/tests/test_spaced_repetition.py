"""Unit tests cho Spaced Repetition Service (SM-2)."""

from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.spaced_repetition import SpacedRepetitionRequest
from app.services.spaced_repetition_service import compute_next_review

client = TestClient(app)


def make_req(**kwargs):
    defaults = dict(node_id="node-1", quality=4, current_interval=1, current_easiness=2.5, repetitions=0)
    defaults.update(kwargs)
    return SpacedRepetitionRequest(**defaults)


def test_first_successful_review_gives_interval_1():
    result = compute_next_review(make_req(quality=4, repetitions=0, current_interval=0))
    assert result.next_interval == 1
    assert result.new_repetitions == 1
    assert not result.is_reset


def test_second_successful_review_gives_interval_6():
    result = compute_next_review(make_req(quality=4, repetitions=1, current_interval=1))
    assert result.next_interval == 6
    assert result.new_repetitions == 2


def test_subsequent_review_multiplies_by_easiness():
    result = compute_next_review(make_req(quality=4, repetitions=2, current_interval=6, current_easiness=2.5))
    assert result.next_interval == round(6 * 2.5)


def test_low_quality_resets_streak():
    result = compute_next_review(make_req(quality=2, repetitions=5, current_interval=30))
    assert result.is_reset
    assert result.next_interval == 1
    assert result.new_repetitions == 0


def test_easiness_increases_with_high_quality():
    result = compute_next_review(make_req(quality=5, current_easiness=2.5))
    assert result.new_easiness > 2.5


def test_easiness_decreases_with_low_quality():
    result = compute_next_review(make_req(quality=3, current_easiness=2.5))
    assert result.new_easiness < 2.5


def test_easiness_never_below_minimum():
    result = compute_next_review(make_req(quality=0, current_easiness=1.3))
    assert result.new_easiness >= 1.3


def test_next_review_date_is_today_plus_interval():
    req = make_req(quality=4, repetitions=0, current_interval=0)
    result = compute_next_review(req)
    assert result.next_review_date == date.today() + timedelta(days=result.next_interval)


def test_api_endpoint_returns_200():
    resp = client.post("/spaced-repetition", json={
        "node_id": "abc-123",
        "quality": 4,
        "current_interval": 6,
        "current_easiness": 2.5,
        "repetitions": 2,
    })
    assert resp.status_code == 200
    body = resp.json()
    assert "next_interval" in body
    assert "next_review_date" in body
    assert "is_reset" in body


def test_api_rejects_invalid_quality():
    resp = client.post("/spaced-repetition", json={
        "node_id": "abc-123",
        "quality": 6,  # > 5, invalid
    })
    assert resp.status_code == 422
