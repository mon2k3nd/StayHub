package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class AttendanceResponse {
    private Long id;
    private Long staffId;
    private String staffName;
    private Long branchId;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInLocation;
    private String checkOutLocation;
    private Double distanceMeters;
    private String status;
}
