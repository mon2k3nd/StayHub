package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class StaffTaskResponse {
    private Long id;
    private Long branchId;
    private Long assignedStaffId;
    private String assignedStaffName;
    private Long createdById;
    private String createdByName;
    private String title;
    private String description;
    private String priority;
    private String status;
    private LocalDateTime dueDate;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
