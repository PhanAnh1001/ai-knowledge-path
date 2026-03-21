from pydantic import BaseModel, Field


class ScoreRequest(BaseModel):
    raw_score: float = Field(..., ge=0, le=100, description="Điểm thô người dùng đạt được (0–100)")
    duration_seconds: int = Field(..., ge=0, description="Thời gian hoàn thành (giây)")
    difficulty: int = Field(..., ge=1, le=5, description="Độ khó node (1–5)")
    hints_used: int = Field(default=0, ge=0, le=3, description="Số gợi ý đã dùng")
    ideal_duration_seconds: int = Field(default=300, ge=30, description="Thời gian lý tưởng (giây)")


class ScoreResponse(BaseModel):
    adaptive_score: float = Field(..., description="Điểm thích nghi (0–100)")
    difficulty_bonus: float = Field(..., description="Hệ số thưởng độ khó")
    speed_bonus: float = Field(..., description="Hệ số thưởng tốc độ")
    hint_penalty: float = Field(..., description="Hệ số phạt gợi ý")
    mastery_delta: float = Field(..., description="Mức độ nắm vững tăng thêm (0–1)")
    curiosity_boost: float = Field(..., description="Điểm tò mò tăng thêm (0–1)")
