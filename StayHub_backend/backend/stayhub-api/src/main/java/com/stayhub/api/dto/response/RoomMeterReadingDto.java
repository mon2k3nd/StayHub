package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomMeterReadingDto {
    private Long roomId;
    private String roomName;
    private Long currentTenantId;
    private Long currentContractId;
    private Double electricPrevious;
    private Double waterPrevious;
    private Double electricCurrent;
    private Double waterCurrent;
    private Long currentMonthBillId;
    private Integer month;
    private Integer year;
}
