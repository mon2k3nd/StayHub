package com.stayhub.api.service;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.StaffTaskRequest;
import com.stayhub.api.dto.request.TaskStatusUpdateRequest;
import com.stayhub.api.dto.response.StaffTaskResponse;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

public interface StaffTaskService {
    ApiResponse<StaffTaskResponse> createTask(StaffTaskRequest request);
    ApiResponse<List<StaffTaskResponse>> getTasksByBranch(Long branchId, String status);
    ApiResponse<List<StaffTaskResponse>> getTasksByStaff(Long staffId);
    ApiResponse<StaffTaskResponse> updateTaskStatus(Long taskId, TaskStatusUpdateRequest request);
    ApiResponse<StaffTaskResponse> updateTaskAssignee(Long taskId, Long staffId);
    
    SseEmitter registerStaffEmitter(Long staffId);
}
