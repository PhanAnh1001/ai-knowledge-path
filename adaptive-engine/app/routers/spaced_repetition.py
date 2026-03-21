from fastapi import APIRouter

from app.schemas.spaced_repetition import SpacedRepetitionRequest, SpacedRepetitionResponse
from app.services.spaced_repetition_service import compute_next_review

router = APIRouter()


@router.post("", response_model=SpacedRepetitionResponse)
def next_review(request: SpacedRepetitionRequest) -> SpacedRepetitionResponse:
    """
    Tính lịch ôn lại tiếp theo theo thuật toán SM-2.

    quality 0–2: quên → reset chuỗi ôn
    quality 3–5: nhớ → kéo dài khoảng cách ôn
    """
    return compute_next_review(request)
