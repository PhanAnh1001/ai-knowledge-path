package com.aiwisdombattle.service;

import com.aiwisdombattle.client.AdaptiveEngineClient;
import com.aiwisdombattle.client.AdaptiveEngineClient.SpacedRepetitionResponse;
import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.entity.Session;
import com.aiwisdombattle.domain.entity.Session.SessionStatus;
import com.aiwisdombattle.dto.response.SessionStartResponse;
import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.domain.entity.UserNodeProgress;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import com.aiwisdombattle.repository.SessionRepository;
import com.aiwisdombattle.repository.UserNodeProgressRepository;
import com.aiwisdombattle.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SessionServiceTest {

    @Mock SessionRepository sessionRepository;
    @Mock KnowledgeNodeRepository nodeRepository;
    @Mock KnowledgeNodeGraphRepository graphRepository;
    @Mock UserRepository userRepository;
    @Mock UserNodeProgressRepository progressRepository;
    @Mock AdaptiveEngineClient adaptiveEngineClient;

    @InjectMocks SessionService sessionService;

    private User user;
    private KnowledgeNode node;
    private Session session;

    @BeforeEach
    void setUp() {
        user = User.builder()
            .id(UUID.randomUUID())
            .email("test@example.com")
            .displayName("TestUser")
            .passwordHash("hash")
            .build();

        node = KnowledgeNode.builder()
            .id(UUID.randomUUID())
            .title("Tại sao bạch tuộc có 3 trái tim?")
            .hook("Bạch tuộc có 3 tim...")
            .domain("nature")
            .published(true)
            .build();

        session = Session.builder()
            .id(UUID.randomUUID())
            .user(user)
            .knowledgeNode(node)
            .build();
    }

    @Test
    void startSession_createsNewSession_whenNoneExists() {
        when(sessionRepository.findByUserIdAndKnowledgeNodeId(user.getId(), node.getId()))
            .thenReturn(Optional.empty());
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(nodeRepository.findById(node.getId())).thenReturn(Optional.of(node));
        when(sessionRepository.save(any())).thenReturn(session);

        SessionStartResponse result = sessionService.startSession(user.getId(), node.getId());

        assertThat(result).isNotNull();
        assertThat(result.getSessionId()).isNotNull();
        verify(sessionRepository).save(any(Session.class));
    }

    @Test
    void startSession_returnsExistingSession_whenInProgress() {
        when(nodeRepository.findById(node.getId())).thenReturn(Optional.of(node));
        when(sessionRepository.findByUserIdAndKnowledgeNodeId(user.getId(), node.getId()))
            .thenReturn(Optional.of(session));

        SessionStartResponse result = sessionService.startSession(user.getId(), node.getId());

        assertThat(result.getSessionId()).isEqualTo(session.getId());
        verify(sessionRepository, never()).save(any());
    }

    @Test
    void startSession_throwsException_whenUserNotFound() {
        when(nodeRepository.findById(node.getId())).thenReturn(Optional.of(node));
        when(sessionRepository.findByUserIdAndKnowledgeNodeId(any(), any()))
            .thenReturn(Optional.empty());
        when(userRepository.findById(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> sessionService.startSession(UUID.randomUUID(), node.getId()))
            .isInstanceOf(com.aiwisdombattle.exception.ResourceNotFoundException.class)
            .hasMessageContaining("User");
    }

    @Test
    void completeSession_updatesStatusAndReturnsSuggestions() {
        SpacedRepetitionResponse sm2 = new SpacedRepetitionResponse(
            node.getId().toString(), 6, 2.5, 1, "2026-04-01", false
        );
        when(sessionRepository.findById(session.getId())).thenReturn(Optional.of(session));
        when(sessionRepository.save(any())).thenReturn(session);
        when(userRepository.save(any())).thenReturn(user);
        when(sessionRepository.findCompletedNodeIdsByUserId(user.getId()))
            .thenReturn(List.of(node.getId()));
        when(graphRepository.findNextSuggestions(any(), any()))
            .thenReturn(List.of(new KnowledgeNodeGraph()));
        when(adaptiveEngineClient.computeAdaptiveScore(anyInt(), anyInt(), anyInt()))
            .thenReturn(88.5);
        when(progressRepository.findByUserIdAndNodeId(any(), any()))
            .thenReturn(Optional.empty());
        when(adaptiveEngineClient.computeNextReview(anyString(), anyInt(), anyInt(), anyDouble(), anyInt()))
            .thenReturn(sm2);
        when(progressRepository.save(any())).thenReturn(UserNodeProgress.builder()
            .userId(user.getId()).nodeId(node.getId()).build());

        SessionCompleteResponse response = sessionService.completeSession(session.getId(), 85, 300);

        assertThat(response.getSessionId()).isEqualTo(session.getId());
        assertThat(response.getScore()).isEqualTo(85);
        assertThat(response.getAdaptiveScore()).isEqualTo(88.5);
        assertThat(response.getNextSuggestions()).hasSize(1);
        assertThat(session.getStatus()).isEqualTo(SessionStatus.COMPLETED);
        verify(progressRepository).save(any(UserNodeProgress.class));
    }

    @Test
    void completeSession_savesProgress_withSm2FallbackWhenEngineDown() {
        when(sessionRepository.findById(session.getId())).thenReturn(Optional.of(session));
        when(sessionRepository.save(any())).thenReturn(session);
        when(userRepository.save(any())).thenReturn(user);
        when(sessionRepository.findCompletedNodeIdsByUserId(user.getId())).thenReturn(List.of());
        when(graphRepository.findNextSuggestions(any(), any())).thenReturn(List.of());
        when(adaptiveEngineClient.computeAdaptiveScore(anyInt(), anyInt(), anyInt())).thenReturn(70.0);
        when(progressRepository.findByUserIdAndNodeId(any(), any())).thenReturn(Optional.empty());
        when(adaptiveEngineClient.computeNextReview(anyString(), anyInt(), anyInt(), anyDouble(), anyInt()))
            .thenReturn(null);  // engine down
        when(progressRepository.save(any())).thenReturn(UserNodeProgress.builder()
            .userId(user.getId()).nodeId(node.getId()).build());

        sessionService.completeSession(session.getId(), 70, 200);

        // Phải vẫn save progress dù engine không phản hồi (fallback 1 ngày)
        verify(progressRepository).save(any(UserNodeProgress.class));
    }
}
