package com.aiwisdombattle.controller;

import com.aiwisdombattle.dto.request.CompleteSessionRequest;
import com.aiwisdombattle.dto.request.StartSessionRequest;
import com.aiwisdombattle.dto.response.SessionCompleteResponse;
import com.aiwisdombattle.dto.response.SessionStartResponse;
import com.aiwisdombattle.service.SessionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "Sessions", description = "Bắt đầu và hoàn thành session học")
@SecurityRequirement(name = "bearerAuth")
public class SessionController {

    private final SessionService sessionService;

    @Operation(summary = "Bắt đầu session học mới",
        responses = {
            @ApiResponse(responseCode = "200", description = "Trả về sessionId + nội dung 6 giai đoạn của node"),
            @ApiResponse(responseCode = "404", description = "User hoặc node không tồn tại")
        })
    @PostMapping
    public ResponseEntity<SessionStartResponse> start(
        @AuthenticationPrincipal UserDetails principal,
        @Valid @RequestBody StartSessionRequest request
    ) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(sessionService.startSession(userId, request.getNodeId()));
    }

    @Operation(summary = "Hoàn thành session và nhận gợi ý node tiếp theo",
        responses = {
            @ApiResponse(responseCode = "200", description = "Trả về adaptive score + 3 node gợi ý"),
            @ApiResponse(responseCode = "404", description = "Session không tồn tại")
        })
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
