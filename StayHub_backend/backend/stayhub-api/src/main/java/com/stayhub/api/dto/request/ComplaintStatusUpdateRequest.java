package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class ComplaintStatusUpdateRequest {
    private String status; // PENDING, PROCESSING, RESOLVED, REJECTED
    private String adminNote;
}
