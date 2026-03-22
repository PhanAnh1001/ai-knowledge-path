package com.aiwisdombattle.service;

import com.aiwisdombattle.client.AdaptiveEngineClient;
import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.entity.Session;
import com.aiwisdombattle.domain.entity.Session.SessionStatus;
import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.dto.response.KnowledgeNodeResponse;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.dto.response.SessionStartResponse;
import com.aiwisdombattle.exception.ResourceNotFoundException;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import com.aiwisdombattle.repository.SessionRepository;
import com.aiwisdombattle.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final SessionRepository sessionRepository;
    private final KnowledgeNodeRepository nodeRepository;
    private final KnowledgeNodeGraphRepository graphRepository;
    private final UserRepository userRepository;
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
}
