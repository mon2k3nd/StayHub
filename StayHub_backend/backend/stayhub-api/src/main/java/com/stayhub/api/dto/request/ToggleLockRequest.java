package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class ToggleLockRequest {
    private Long deviceId;
    private Boolean isLocked;
}
