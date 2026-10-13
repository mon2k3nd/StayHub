package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class TaskStatusUpdateRequest {
    private String status; // TODO, IN_PROGRESS, DONE
}
