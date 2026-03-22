package com.aiwisdombattle.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Trạng thái SM-2 (Spaced Repetition) của một user với một knowledge node.
 * Mỗi cặp (userId, nodeId) có tối đa một bản ghi, được cập nhật sau mỗi session.
 */
@Entity
@Table(
    name = "user_node_progress",
    uniqueConstraints = @UniqueConstraint(
        name = "uc_user_node_progress_user_node",
        columnNames = {"user_id", "node_id"}
    )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserNodeProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "node_id", nullable = false)
    private UUID nodeId;

    /** Số lần đã ôn thành công (quality >= 3) */
    @Column(name = "sm2_repetitions", nullable = false)
    @Builder.Default
    private int sm2Repetitions = 0;

    /** Hệ số dễ nhớ EF (Ease Factor), tối thiểu 1.3 */
    @Column(name = "sm2_easiness", nullable = false)
    @Builder.Default
    private double sm2Easiness = 2.5;

    /** Khoảng cách ôn lại hiện tại (ngày) */
    @Column(name = "sm2_interval", nullable = false)
    @Builder.Default
    private int sm2Interval = 0;

    /** Ngày ôn lại tiếp theo */
    @Column(name = "next_review_date")
    private LocalDate nextReviewDate;

    @Column(name = "last_reviewed_at", nullable = false)
    @Builder.Default
    private Instant lastReviewedAt = Instant.now();
}
