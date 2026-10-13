package com.stayhub.api.dto.response;

import com.stayhub.api.entity.RequestStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentalRequestResponseDto {
    private Long id;
    private Long tenantId;
    private String tenantName;
    private String phone;
    private Long roomId;
    private String roomName;
    private Long branchId;
    private String branchName;
    private LocalDate moveInDate;
    private String note;
    private RequestStatus status;
    private LocalDateTime submittedAt;
}
