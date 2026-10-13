package com.stayhub.api.dto.request;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class StaffTaskRequest {
    private Long branchId;
    private Long assignedStaffId;
    private Long createdById;
    private String title;
    private String description;
    private String priority;
    private LocalDateTime dueDate;
}
