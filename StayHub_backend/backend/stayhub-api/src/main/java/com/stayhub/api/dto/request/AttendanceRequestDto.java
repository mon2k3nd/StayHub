package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class AttendanceRequestDto {
    private Long branchId;
    private String location; // GPS coordinates or physical location name
    private Double latitude;
    private Double longitude;
    private String photoBase64;
}
