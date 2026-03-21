package com.aiwisdombattle.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.UUID;

@Getter
public class StartSessionRequest {

    @NotNull
    private UUID nodeId;
}
