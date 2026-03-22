package com.aiwisdombattle.dto.response;

import com.aiwisdombattle.domain.entity.KnowledgeNode;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

/**
 * DTO trả về nội dung đầy đủ của một KnowledgeNode cho frontend.
 * Bao gồm cả 6 giai đoạn session: hook → guess → journey → reveal → teach-back → payoff.
 */
@Getter
@Builder
public class KnowledgeNodeResponse {

    private UUID id;
    private String title;
    private String domain;
    private String ageGroup;
    private int difficulty;
    private int curiosityScore;

    // ① Hook
    private String hook;

    // ② Your Guess
    private String guessPrompt;

    // ③ The Journey (JSONB: [{step, text}])
    private String journeySteps;

    // ④ The Reveal
    private String revealText;

    // ⑤ Teach It Back
    private String teachBackPrompt;

    // ⑥ The Payoff
    private String payoffInsight;

    public static KnowledgeNodeResponse from(KnowledgeNode node) {
        return KnowledgeNodeResponse.builder()
            .id(node.getId())
            .title(node.getTitle())
            .domain(node.getDomain())
            .ageGroup(node.getAgeGroup())
            .difficulty(node.getDifficulty())
            .curiosityScore(node.getCuriosityScore())
            .hook(node.getHook())
            .guessPrompt(node.getGuessPrompt())
            .journeySteps(node.getJourneySteps())
            .revealText(node.getRevealText())
            .teachBackPrompt(node.getTeachBackPrompt())
            .payoffInsight(node.getPayoffInsight())
            .build();
    }
}
