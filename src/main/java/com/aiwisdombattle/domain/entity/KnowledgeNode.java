package com.aiwisdombattle.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Một chủ đề kiến thức — tương ứng với 1 session học.
 * Đây là bản ghi trong PostgreSQL; bản Neo4j lưu graph relationships riêng.
 */
@Entity
@Table(name = "knowledge_nodes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KnowledgeNode {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, length = 120)
    private String title;

    /** Câu hook gây tò mò — hiển thị trước khi mở session */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String hook;

    /** nature | technology | history | creative */
    @Column(nullable = false, length = 20)
    private String domain;

    /** child_8_10 | teen_11_17 | adult_18_plus | all */
    @Column(name = "age_group", nullable = false, length = 20)
    @Builder.Default
    private String ageGroup = "all";

    /** Độ khó 1–5 */
    @Column(nullable = false)
    @Builder.Default
    private int difficulty = 2;

    /** Độ tò mò 1–10 — dùng để ưu tiên làm Hook */
    @Column(name = "curiosity_score", nullable = false)
    @Builder.Default
    private int curiosityScore = 5;

    @Column(name = "is_published", nullable = false)
    @Builder.Default
    private boolean published = false;

    /** ② YOUR GUESS — câu hỏi để người dùng đoán trước khi xem lời giải */
    @Column(name = "guess_prompt", columnDefinition = "TEXT")
    private String guessPrompt;

    /** ③ THE JOURNEY — mảng 3–4 insights dạng JSON: [{step, text}] */
    @Column(name = "journey_steps", columnDefinition = "JSONB")
    private String journeySteps;

    /** ④ THE REVEAL — đối chiếu dự đoán với câu trả lời thật */
    @Column(name = "reveal_text", columnDefinition = "TEXT")
    private String revealText;

    /** ⑤ TEACH IT BACK — prompt Feynman Technique: giải thích lại cho nhân vật ảo */
    @Column(name = "teach_back_prompt", columnDefinition = "TEXT")
    private String teachBackPrompt;

    /** ⑥ THE PAYOFF — insight "wow" kết thúc session, mở cửa cho hành trình tiếp theo */
    @Column(name = "payoff_insight", columnDefinition = "TEXT")
    private String payoffInsight;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
