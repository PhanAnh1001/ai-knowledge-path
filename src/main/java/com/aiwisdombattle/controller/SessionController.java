package com.aiwisdombattle.controller;

import com.aiwisdombattle.domain.entity.Session;
import com.aiwisdombattle.dto.request.CompleteSessionRequest;
import com.aiwisdombattle.dto.request.StartSessionRequest;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.service.SessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    /**
     * POST /api/v1/sessions
     * Bắt đầu một session học mới.
     */
    @PostMapping
    public ResponseEntity<Session> start(
        @AuthenticationPrincipal UserDetails principal,
        @Valid @RequestBody StartSessionRequest request
    ) {
        UUID userId = UUID.fromString(principal.getUsername());
        Session session = sessionService.startSession(userId, request.getNodeId());
        return ResponseEntity.ok(session);
    }

    /**
     * POST /api/v1/sessions/complete
     * Hoàn thành session và nhận gợi ý 3 node tiếp theo.
     */
    @PostMapping("/complete")
    public ResponseEntity<SessionCompleteResponse> complete(
        @AuthenticationPrincipal UserDetails principal,
        @Valid @RequestBody CompleteSessionRequest request
    ) {
        SessionCompleteResponse response = sessionService.completeSession(
            request.getSessionId(),
            request.getScore(),
            request.getDurationSeconds()
        );
        return ResponseEntity.ok(response);
    }
}
