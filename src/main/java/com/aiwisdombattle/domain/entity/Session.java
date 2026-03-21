package com.aiwisdombattle.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Lịch sử một session học của người dùng.
 * Trạng thái: IN_PROGRESS | COMPLETED | ABANDONED
 */
@Entity
@Table(name = "sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Session {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "knowledge_node_id", nullable = false)
    private KnowledgeNode knowledgeNode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private SessionStatus status = SessionStatus.IN_PROGRESS;

    /** Điểm đạt được khi hoàn thành (0 nếu chưa xong) */
    @Column(name = "score_earned")
    @Builder.Default
    private int scoreEarned = 0;

    /** Thời gian hoàn thành tính bằng giây */
    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "started_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant startedAt = Instant.now();

    @Column(name = "completed_at")
    private Instant completedAt;

    public enum SessionStatus {
        IN_PROGRESS, COMPLETED, ABANDONED
    }
}
