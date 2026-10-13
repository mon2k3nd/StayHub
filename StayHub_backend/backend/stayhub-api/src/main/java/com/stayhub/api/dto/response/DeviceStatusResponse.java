package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceStatusResponse {
    private Long deviceId;
    private Long roomId;
    private Integer deviceType;
    private Boolean isLocked;
    private Double lastRecordedValue;
    private LocalDateTime lastSyncTime;
    private String statusMessage;
}
