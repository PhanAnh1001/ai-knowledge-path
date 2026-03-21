package com.aiwisdombattle.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Người dùng của hệ thống.
 * Ánh xạ tới bảng {@code users} trong PostgreSQL.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    /** Tên hiển thị trên bảng xếp hạng */
    @Column(name = "display_name", nullable = false, length = 50)
    private String displayName;

    /** Mật khẩu đã hash (BCrypt) */
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    /** Loại explorer: nature | technology | history | creative */
    @Column(name = "explorer_type", length = 20)
    private String explorerType;

    /** Nhóm tuổi: child_8_10 | teen_11_17 | adult_18_plus */
    @Column(name = "age_group", length = 20)
    private String ageGroup;

    @Column(name = "streak_days")
    @Builder.Default
    private int streakDays = 0;

    @Column(name = "total_sessions")
    @Builder.Default
    private int totalSessions = 0;

    /** Premium hoặc free */
    @Column(name = "is_premium")
    @Builder.Default
    private boolean premium = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    @Builder.Default
    private Instant updatedAt = Instant.now();

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
