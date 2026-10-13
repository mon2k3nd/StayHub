package com.stayhub.api.service;

import com.stayhub.api.dto.ChecklistItemDto;
import com.stayhub.api.dto.HousekeepingTaskDto;

import java.util.List;

public interface HousekeepingService {
    List<HousekeepingTaskDto> getTasksByBranch(Long branchId);
    HousekeepingTaskDto updateTaskStatus(Long taskId, String status);
    HousekeepingTaskDto updateChecklist(Long taskId, List<ChecklistItemDto> checklist);
}
