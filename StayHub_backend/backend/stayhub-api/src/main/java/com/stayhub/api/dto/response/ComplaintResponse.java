package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ComplaintResponse {
    private Long id;
    private Long tenantId;
    private String tenantName;
    private String tenantPhone;
    private Long branchId;
    private Long roomId;
    private String roomName;
    private String category;
    private String priority;
    private String title;
    private String description;
    private List<String> images;
    private String status;
    private String adminNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
