package com.aiwisdombattle.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

/**
 * HTTP client gọi Python Adaptive Engine (FastAPI port 8001).
 * Mọi lỗi (timeout, service down) đều fallback về rawScore để không block luồng chính.
 */
@Component
@Slf4j
public class AdaptiveEngineClient {

    private final RestTemplate restTemplate;

    public AdaptiveEngineClient(RestTemplate adaptiveEngineRestTemplate) {
        this.restTemplate = adaptiveEngineRestTemplate;
    }

    // ── Request / Response records ──────────────────────────────────────────

    public record ScoreRequest(
        int rawScore,
        int durationSeconds,
        int difficulty,
        int hintsUsed,
        int idealDurationSeconds
    ) {}

    public record ScoreResponse(
        double adaptiveScore,
        double difficultyBonus,
        double speedBonus,
        double hintPenalty,
        double masteryDelta,
        double curiosityBoost
    ) {}

    public record SpacedRepetitionRequest(
        String nodeId,
        int quality,
        int currentInterval,
        double currentEasiness,
        int repetitions
    ) {}

    public record SpacedRepetitionResponse(
        String nodeId,
        int nextInterval,
        double newEasiness,
        int newRepetitions,
        String nextReviewDate,  // ISO date string "YYYY-MM-DD"
        boolean isReset
    ) {}

    // ── Public API ──────────────────────────────────────────────────────────

    /**
     * Tính điểm thích nghi. Nếu Python engine không phản hồi, trả về rawScore.
     *
     * @param rawScore          điểm thô (0–100)
     * @param durationSeconds   thời gian thực tế (giây)
     * @param difficulty        độ khó node (1–5)
     * @return điểm thích nghi (0–100)
     */
    public double computeAdaptiveScore(int rawScore, int durationSeconds, int difficulty) {
        try {
            var request = new ScoreRequest(rawScore, durationSeconds, difficulty, 0, 300);
            var response = restTemplate.postForObject("/scoring", request, ScoreResponse.class);
            if (response != null) {
                return response.adaptiveScore();
            }
        } catch (Exception ex) {
            log.warn("AdaptiveEngine unavailable — falling back to rawScore. Cause: {}", ex.getMessage());
        }
        return rawScore;
    }

    /**
     * Tính lịch ôn tiếp theo theo thuật toán SM-2.
     * Nếu Python engine không phản hồi, trả về null để caller dùng fallback.
     *
     * @param nodeId            UUID của knowledge node
     * @param quality           chất lượng trả lời (0–5); ánh xạ từ adaptiveScore
     * @param currentInterval   khoảng cách ôn hiện tại (ngày)
     * @param currentEasiness   hệ số dễ nhớ hiện tại (mặc định 2.5)
     * @param repetitions       số lần đã ôn thành công
     * @return kết quả SM-2, hoặc null nếu engine không phản hồi
     */
    public SpacedRepetitionResponse computeNextReview(
        String nodeId,
        int quality,
        int currentInterval,
        double currentEasiness,
        int repetitions
    ) {
        try {
            var request = new SpacedRepetitionRequest(
                nodeId, quality, currentInterval, currentEasiness, repetitions
            );
            return restTemplate.postForObject("/spaced-repetition", request, SpacedRepetitionResponse.class);
        } catch (Exception ex) {
            log.warn("AdaptiveEngine SM-2 unavailable for node {}. Cause: {}", nodeId, ex.getMessage());
            return null;
        }
    }
}
