package com.aiwisdombattle.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.UUID;

@Getter
public class CompleteSessionRequest {

    @NotNull
    private UUID sessionId;

    @Min(0) @Max(100)
    private int score;

    @Min(0)
    private int durationSeconds;
}
