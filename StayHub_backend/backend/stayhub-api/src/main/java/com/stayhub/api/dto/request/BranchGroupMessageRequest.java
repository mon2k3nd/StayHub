package com.stayhub.api.dto.request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchGroupMessageRequest {
    private String content;
    private String messageType; // "TEXT", "IMAGE", "VOICE"
}
