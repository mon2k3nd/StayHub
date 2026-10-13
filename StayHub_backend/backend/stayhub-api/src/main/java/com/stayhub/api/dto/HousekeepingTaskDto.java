package com.stayhub.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HousekeepingTaskDto {
    private Long id;
    private Long branchId;
    private Long roomId;
    private String roomName;
    private String type;     // mapped from taskType
    private String status;
    private String dueTime;
    private List<ChecklistItemDto> checklist;
}
