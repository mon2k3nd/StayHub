package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class BranchGroupMessageDto {
    private Long id;
    private Long branchId;
    private Long senderId;
    private String senderName;
    private String senderRole; // "OWNER", "TENANT", "SYSTEM"
    private String roomNumber; // e.g. "Phòng 101"
    private String messageType; // "TEXT", "IMAGE", "VOICE"
    private String content; // Text content or URL for image/voice
    private LocalDateTime createdAt;
}
