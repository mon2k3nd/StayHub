package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class AttendanceRequest {
    private Double latitude;
    private Double longitude;
    private String photo; // Base64 or URL
    private String locationAddress;
}
