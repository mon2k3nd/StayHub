package com.stayhub.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DirectChatMessageRequest {
    private String content;
    private String messageType;
    private Long receiverId;
}
