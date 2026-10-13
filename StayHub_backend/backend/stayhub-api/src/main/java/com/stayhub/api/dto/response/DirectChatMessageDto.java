package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DirectChatMessageDto {
    private Long id;
    private Long senderId;
    private Long receiverId;
    private String content;
    private String messageType;
    private boolean isRead;
    private LocalDateTime createdAt;
}
