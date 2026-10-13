package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AttendanceDto {
    private Long id;
    private Long staffId;
    private Long branchId;
    private String branchName;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInLocation;
    private String checkOutLocation;
    private Double latitude;
    private Double longitude;
    private Double distanceMeters;
    private String status;
    private String checkInPhotoUrl;
    private String checkOutPhotoUrl;
}
