package com.aiwisdombattle.service;

import com.aiwisdombattle.client.AdaptiveEngineClient;
import com.aiwisdombattle.client.AdaptiveEngineClient.SpacedRepetitionResponse;
import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.entity.Session;
import com.aiwisdombattle.domain.entity.Session.SessionStatus;
import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.domain.entity.UserNodeProgress;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.dto.response.KnowledgeNodeResponse;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.dto.response.SessionStartResponse;
import com.aiwisdombattle.exception.ResourceNotFoundException;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import com.aiwisdombattle.repository.SessionRepository;
import com.aiwisdombattle.repository.UserNodeProgressRepository;
import com.aiwisdombattle.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SessionService {

    private final SessionRepository sessionRepository;
    private final KnowledgeNodeRepository nodeRepository;
    private final KnowledgeNodeGraphRepository graphRepository;
    private final UserRepository userRepository;
    private final UserNodeProgressRepository progressRepository;
    private final AdaptiveEngineClient adaptiveEngineClient;

    /**
     * Bắt đầu một session mới. Nếu đã có IN_PROGRESS thì trả về session cũ.
     * Trả về sessionId + toàn bộ nội dung 6 giai đoạn của node để frontend
     * render ngay mà không cần gọi thêm request.
     */
    @Transactional
    public SessionStartResponse startSession(UUID userId, UUID nodeId) {
        KnowledgeNode node = nodeRepository.findById(nodeId)
            .orElseThrow(() -> ResourceNotFoundException.of("Node", nodeId));

        Session session = sessionRepository.findByUserIdAndKnowledgeNodeId(userId, nodeId)
            .filter(s -> s.getStatus() == SessionStatus.IN_PROGRESS)
            .orElseGet(() -> {
                User user = userRepository.findById(userId)
                    .orElseThrow(() -> ResourceNotFoundException.of("User", userId));
                return sessionRepository.save(
                    Session.builder().user(user).knowledgeNode(node).build()
                );
            });

        return SessionStartResponse.builder()
            .sessionId(session.getId())
            .node(KnowledgeNodeResponse.from(node))
            .build();
    }

    /**
     * Hoàn thành một session và trả về gợi ý 3 node tiếp theo.
     * Adaptive score được tính từ Python FastAPI engine (fallback = rawScore nếu engine down).
     */
    @Transactional
    public SessionCompleteResponse completeSession(UUID sessionId, int score, int durationSeconds) {
        Session session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> ResourceNotFoundException.of("Session", sessionId));

        session.setStatus(SessionStatus.COMPLETED);
        session.setScoreEarned(score);
        session.setDurationSeconds(durationSeconds);
        session.setCompletedAt(Instant.now());
        sessionRepository.save(session);

        // Cập nhật tổng số session của user
        User user = session.getUser();
        user.setTotalSessions(user.getTotalSessions() + 1);
        userRepository.save(user);

        // Gọi Python Adaptive Engine để tính điểm thích nghi
        int difficulty = session.getKnowledgeNode().getDifficulty();
        double adaptiveScore = adaptiveEngineClient.computeAdaptiveScore(score, durationSeconds, difficulty);

        // Cập nhật trạng thái SM-2 cho cặp (user, node)
        updateSpacedRepetition(user.getId(), session.getKnowledgeNode(), adaptiveScore);

        // Lấy gợi ý tiếp theo từ Neo4j
        List<UUID> seenUuids = sessionRepository.findCompletedNodeIdsByUserId(user.getId());
        List<String> seenIds = seenUuids.stream().map(UUID::toString).toList();
        String completedNodeId = session.getKnowledgeNode().getId().toString();
        List<KnowledgeNodeGraph> suggestions = graphRepository.findNextSuggestions(completedNodeId, seenIds);

        return SessionCompleteResponse.builder()
            .sessionId(session.getId())
            .score(score)
            .adaptiveScore(adaptiveScore)
            .nextSuggestions(suggestions)
            .build();
    }

    /**
     * Tính và lưu lịch ôn SM-2 cho cặp (userId, node).
     * Ánh xạ adaptiveScore (0–100) sang quality SM-2 (0–5).
     * Nếu engine không phản hồi, fallback về interval 1 ngày.
     */
    private void updateSpacedRepetition(UUID userId, KnowledgeNode node, double adaptiveScore) {
        int quality = (int) Math.round(adaptiveScore / 100.0 * 5);
        quality = Math.max(0, Math.min(5, quality));

        UserNodeProgress progress = progressRepository
            .findByUserIdAndNodeId(userId, node.getId())
            .orElseGet(() -> UserNodeProgress.builder()
                .userId(userId)
                .nodeId(node.getId())
                .build());

        SpacedRepetitionResponse sm2 = adaptiveEngineClient.computeNextReview(
            node.getId().toString(),
            quality,
            progress.getSm2Interval(),
            progress.getSm2Easiness(),
            progress.getSm2Repetitions()
        );

        if (sm2 != null) {
            progress.setSm2Repetitions(sm2.newRepetitions());
            progress.setSm2Easiness(sm2.newEasiness());
            progress.setSm2Interval(sm2.nextInterval());
            progress.setNextReviewDate(LocalDate.parse(sm2.nextReviewDate()));
        } else {
            // Fallback: ôn lại sau 1 ngày nếu engine không phản hồi
            progress.setNextReviewDate(LocalDate.now().plusDays(1));
            log.warn("SM-2 fallback for user={} node={}", userId, node.getId());
        }

        progress.setLastReviewedAt(Instant.now());
        progressRepository.save(progress);
    }
}
