from fastapi import APIRouter

from app.schemas.scoring import ScoreRequest, ScoreResponse
from app.services.scoring_service import compute_score

router = APIRouter()


@router.post("", response_model=ScoreResponse)
def score_session(request: ScoreRequest) -> ScoreResponse:
    """
    Tính điểm thích nghi cho một session học.

    Nhận điểm thô, thời gian, độ khó, số gợi ý dùng →
    trả về điểm thích nghi, mastery delta và curiosity boost.
    """
    return compute_score(request)
