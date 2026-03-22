package com.aiwisdombattle.controller;

import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import com.aiwisdombattle.repository.KnowledgeNodeGraphRepository;
import com.aiwisdombattle.repository.SessionRepository;
import com.aiwisdombattle.service.KnowledgeNodeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "Knowledge Nodes", description = "Danh sách node kiến thức và knowledge map")
@SecurityRequirement(name = "bearerAuth")
public class KnowledgeNodeController {

    private final KnowledgeNodeService nodeService;
    private final KnowledgeNodeGraphRepository graphRepository;
    private final SessionRepository sessionRepository;

    @Operation(summary = "Danh sách node chưa học (optional: lọc theo domain)")
    @GetMapping
    public ResponseEntity<List<KnowledgeNode>> listNodes(
        @RequestParam(required = false) String domain,
        @AuthenticationPrincipal UserDetails principal
    ) {
        UUID userId = UUID.fromString(principal.getUsername());
        List<UUID> seenIds = sessionRepository.findCompletedNodeIdsByUserId(userId);

        List<KnowledgeNode> published = (domain != null && !domain.isBlank())
            ? nodeService.getPublishedByDomain(domain)
            : nodeService.getAllPublished();

        return ResponseEntity.ok(nodeService.filterUnseen(published, seenIds));
    }

    @Operation(summary = "Subgraph xung quanh node để render knowledge map")
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

    @Operation(summary = "Chuỗi deep-dive (Rabbit Hole Mode — Premium)")
    @GetMapping("/{nodeId}/deep-dive")
    public ResponseEntity<List<KnowledgeNodeGraph>> deepDive(@PathVariable String nodeId) {
        return ResponseEntity.ok(graphRepository.findDeepDiveChain(nodeId));
    }

    @Operation(summary = "Kết nối bất ngờ xuyên domain (Premium)")
    @GetMapping("/{nodeId}/cross-domain")
    public ResponseEntity<List<KnowledgeNodeGraph>> crossDomain(@PathVariable String nodeId) {
        return ResponseEntity.ok(graphRepository.findCrossDomainSurprises(nodeId));
    }
}
