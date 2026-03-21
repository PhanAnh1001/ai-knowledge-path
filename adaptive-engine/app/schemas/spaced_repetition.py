from datetime import date
from pydantic import BaseModel, Field


class SpacedRepetitionRequest(BaseModel):
    node_id: str = Field(..., description="UUID của knowledge node")
    quality: int = Field(..., ge=0, le=5, description="Chất lượng trả lời (0=quên, 5=hoàn hảo)")
    current_interval: int = Field(default=0, ge=0, description="Khoảng cách ôn lại hiện tại (ngày)")
    current_easiness: float = Field(default=2.5, ge=1.3, le=5.0, description="Hệ số dễ nhớ hiện tại")
    repetitions: int = Field(default=0, ge=0, description="Số lần đã ôn thành công")


class SpacedRepetitionResponse(BaseModel):
    node_id: str
    next_interval: int = Field(..., description="Khoảng cách ôn tiếp theo (ngày)")
    new_easiness: float = Field(..., description="Hệ số dễ nhớ cập nhật")
    new_repetitions: int = Field(..., description="Số lần đã ôn thành công cập nhật")
    next_review_date: date = Field(..., description="Ngày ôn lại tiếp theo")
    is_reset: bool = Field(..., description="True nếu chuỗi ôn bị reset (quality < 3)")
