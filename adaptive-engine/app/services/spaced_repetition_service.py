"""
Spaced Repetition Service — thuật toán SM-2 (SuperMemo 2).

Tham khảo: https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method

Quy tắc:
    - quality 0–2: quên → reset chuỗi (interval=1, repetitions=0)
    - quality 3–5: nhớ được → tiến hành lịch ôn tiếp theo
    - EF mới = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    - EF tối thiểu = 1.3
    - interval:
        - repetitions == 0: 1 ngày
        - repetitions == 1: 6 ngày
        - repetitions >= 2: interval * EF (làm tròn)
"""

from datetime import date, timedelta

from app.schemas.spaced_repetition import SpacedRepetitionRequest, SpacedRepetitionResponse

_MIN_EASINESS = 1.3
_RESET_INTERVAL = 1


def compute_next_review(req: SpacedRepetitionRequest) -> SpacedRepetitionResponse:
    is_reset = req.quality < 3

    if is_reset:
        new_repetitions = 0
        new_interval = _RESET_INTERVAL
    else:
        new_repetitions = req.repetitions + 1
        if new_repetitions == 1:
            new_interval = 1
        elif new_repetitions == 2:
            new_interval = 6
        else:
            new_interval = round(req.current_interval * req.current_easiness)
            new_interval = max(new_interval, 1)

    # Cập nhật hệ số dễ nhớ (EF) cho mọi trường hợp
    ef_delta = 0.1 - (5 - req.quality) * (0.08 + (5 - req.quality) * 0.02)
    new_easiness = max(_MIN_EASINESS, req.current_easiness + ef_delta)

    next_review = date.today() + timedelta(days=new_interval)

    return SpacedRepetitionResponse(
        node_id=req.node_id,
        next_interval=new_interval,
        new_easiness=round(new_easiness, 4),
        new_repetitions=new_repetitions,
        next_review_date=next_review,
        is_reset=is_reset,
    )
