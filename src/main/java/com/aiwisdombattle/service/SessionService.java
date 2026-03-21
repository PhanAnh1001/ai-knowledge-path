package com.aiwisdombattle.service;

import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.entity.Session;
import com.aiwisdombattle.domain.entity.Session.SessionStatus;
import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import com.aiwisdombattle.repository.SessionRepository;
import com.aiwisdombattle.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final SessionRepository sessionRepository;
    private final KnowledgeNodeRepository nodeRepository;
    private final KnowledgeNodeGraphRepository graphRepository;
    private final UserRepository userRepository;

    /** Bắt đầu một session mới. Nếu đã có IN_PROGRESS thì trả về session cũ. */
    @Transactional
    public Session startSession(UUID userId, UUID nodeId) {
        return sessionRepository.findByUserIdAndKnowledgeNodeId(userId, nodeId)
            .filter(s -> s.getStatus() == SessionStatus.IN_PROGRESS)
            .orElseGet(() -> {
                User user = userRepository.findById(userId)
                    .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
                KnowledgeNode node = nodeRepository.findById(nodeId)
                    .orElseThrow(() -> new NoSuchElementException("Node not found: " + nodeId));

                return sessionRepository.save(
                    Session.builder().user(user).knowledgeNode(node).build()
                );
            });
    }

    /**
     * Hoàn thành một session và trả về gợi ý 3 node tiếp theo.
     */
    @Transactional
    public SessionCompleteResponse completeSession(UUID sessionId, int score, int durationSeconds) {
        Session session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> new NoSuchElementException("Session not found: " + sessionId));

        session.setStatus(SessionStatus.COMPLETED);
        session.setScoreEarned(score);
        session.setDurationSeconds(durationSeconds);
        session.setCompletedAt(Instant.now());
        sessionRepository.save(session);

        // Cập nhật streak và tổng số session
        User user = session.getUser();
        user.setTotalSessions(user.getTotalSessions() + 1);
        userRepository.save(user);

        // Lấy gợi ý tiếp theo từ Neo4j
        List<UUID> seenUuids = sessionRepository.findCompletedNodeIdsByUserId(user.getId());
        List<String> seenIds = seenUuids.stream().map(UUID::toString).toList();
        String completedNodeId = session.getKnowledgeNode().getId().toString();

        List<KnowledgeNodeGraph> suggestions = graphRepository.findNextSuggestions(completedNodeId, seenIds);

        return SessionCompleteResponse.builder()
            .sessionId(session.getId())
            .score(score)
            .nextSuggestions(suggestions)
            .build();
    }
}
