from fastapi import APIRouter

from app.schemas.recommendation import RecommendationRequest, RecommendationResponse
from app.services.recommendation_service import compute_recommendations

router = APIRouter()


@router.post("", response_model=RecommendationResponse)
def recommend_next_nodes(request: RecommendationRequest) -> RecommendationResponse:
    """
    Gợi ý các knowledge node tiếp theo phù hợp nhất với người dùng.

    Ưu tiên theo thứ tự:
    1. Node đến hạn ôn lại (spaced repetition)
    2. Node có curiosity score cao
    3. Node có độ khó phù hợp với nhóm tuổi
    4. Node thuộc domain yêu thích
    5. Node khám phá mới
    """
    return compute_recommendations(request)
