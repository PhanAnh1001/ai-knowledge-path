package com.aiwisdombattle.controller;

import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import com.aiwisdombattle.repository.SessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/nodes")
@RequiredArgsConstructor
public class KnowledgeNodeController {

    private final KnowledgeNodeRepository nodeRepository;
    private final KnowledgeNodeGraphRepository graphRepository;
    private final SessionRepository sessionRepository;

    /**
     * GET /api/v1/nodes?domain=nature   (domain là optional)
     * Danh sách node chưa học, lọc theo domain nếu có.
     */
    @GetMapping
    public ResponseEntity<List<KnowledgeNode>> listNodes(
        @RequestParam(required = false) String domain,
        @AuthenticationPrincipal UserDetails principal
    ) {
        UUID userId = UUID.fromString(principal.getUsername());
        List<UUID> seenIds = sessionRepository.findCompletedNodeIdsByUserId(userId);
        List<KnowledgeNode> nodes = (domain != null && !domain.isBlank())
            ? nodeRepository.findUnseenByDomain(domain, seenIds)
            : nodeRepository.findAllUnseen(seenIds);
        return ResponseEntity.ok(nodes);
    }

    /**
     * GET /api/v1/nodes/{nodeId}/map
     * Subgraph xung quanh node để render knowledge map.
     */
    @GetMapping("/{nodeId}/map")
    public ResponseEntity<List<KnowledgeNodeGraph>> knowledgeMap(
        @PathVariable String nodeId,
        @AuthenticationPrincipal UserDetails principal
    ) {
        UUID userId = UUID.fromString(principal.getUsername());
        List<UUID> seenUuids = sessionRepository.findCompletedNodeIdsByUserId(userId);
        List<String> seenIds = seenUuids.stream().map(UUID::toString).toList();
        seenIds = seenIds.isEmpty() ? List.of(nodeId) : seenIds;
        return ResponseEntity.ok(graphRepository.findKnowledgeMapSubgraph(seenIds));
    }

    /**
     * GET /api/v1/nodes/{nodeId}/deep-dive
     * Chuỗi deep-dive (Rabbit Hole Mode — Premium).
     */
    @GetMapping("/{nodeId}/deep-dive")
    public ResponseEntity<List<KnowledgeNodeGraph>> deepDive(@PathVariable String nodeId) {
        return ResponseEntity.ok(graphRepository.findDeepDiveChain(nodeId));
    }

    /**
     * GET /api/v1/nodes/{nodeId}/cross-domain
     * Kết nối bất ngờ xuyên domain (Premium).
     */
    @GetMapping("/{nodeId}/cross-domain")
    public ResponseEntity<List<KnowledgeNodeGraph>> crossDomain(@PathVariable String nodeId) {
        return ResponseEntity.ok(graphRepository.findCrossDomainSurprises(nodeId));
    }
}
