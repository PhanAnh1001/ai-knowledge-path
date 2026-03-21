"""
Scoring Service — tính điểm thích nghi từ điểm thô và các yếu tố ngữ cảnh.

Công thức:
    adaptive_score = raw_score × difficulty_bonus × speed_bonus × (1 - hint_penalty)

Trong đó:
    difficulty_bonus = 1.0 + (difficulty - 1) × 0.1   # range [1.0, 1.4]
    speed_bonus      = clamp(1.0 - overtime_ratio × 0.2, 0.8, 1.0)
    hint_penalty     = hints_used × 0.05               # range [0, 0.15]
"""

from app.schemas.scoring import ScoreRequest, ScoreResponse

_MAX_OVERTIME_RATIO = 1.0  # vượt quá 100% thời gian lý tưởng thì cap penalty


def compute_score(req: ScoreRequest) -> ScoreResponse:
    # Hệ số thưởng độ khó: khó hơn → thưởng nhiều hơn
    difficulty_bonus = 1.0 + (req.difficulty - 1) * 0.1

    # Hệ số thưởng tốc độ: hoàn thành nhanh hơn ideal → bonus; chậm hơn → penalty nhẹ
    overtime_ratio = max(0.0, (req.duration_seconds - req.ideal_duration_seconds) / req.ideal_duration_seconds)
    overtime_ratio = min(overtime_ratio, _MAX_OVERTIME_RATIO)
    speed_bonus = 1.0 - overtime_ratio * 0.2  # range [0.8, 1.0]

    # Hệ số phạt gợi ý
    hint_penalty = req.hints_used * 0.05  # 0, 0.05, 0.10, 0.15

    # Điểm thích nghi (cap tại 100)
    adaptive_score = req.raw_score * difficulty_bonus * speed_bonus * (1.0 - hint_penalty)
    adaptive_score = min(adaptive_score, 100.0)

    # Mức độ nắm vững tăng thêm: tỷ lệ thuận với adaptive_score, tối đa +0.2/session
    mastery_delta = (adaptive_score / 100.0) * 0.2

    # Điểm tò mò tăng thêm: tỷ lệ thuận với difficulty_bonus (khó khám phá thêm nhiều hơn)
    curiosity_boost = round((difficulty_bonus - 1.0) * 0.5 + 0.05, 4)

    return ScoreResponse(
        adaptive_score=round(adaptive_score, 2),
        difficulty_bonus=round(difficulty_bonus, 4),
        speed_bonus=round(speed_bonus, 4),
        hint_penalty=round(hint_penalty, 4),
        mastery_delta=round(mastery_delta, 4),
        curiosity_boost=round(curiosity_boost, 4),
    )
