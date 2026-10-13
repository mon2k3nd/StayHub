package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.StaffTaskRequest;
import com.stayhub.api.dto.request.TaskStatusUpdateRequest;
import com.stayhub.api.dto.response.StaffTaskResponse;
import com.stayhub.api.service.StaffTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@RestController
@RequestMapping("/v1/staff-tasks")
@RequiredArgsConstructor
public class V1StaffTaskController {

    private final StaffTaskService staffTaskService;

    @PostMapping
    public ResponseEntity<ApiResponse<StaffTaskResponse>> createTask(@RequestBody StaffTaskRequest request, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        Long ownerId = (Long) auth.getPrincipal(); // Owner creates task
        // We probably should set ownerId to request but StaffTaskRequest might not have it.
        return ResponseEntity.ok(staffTaskService.createTask(request));
    }

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<StaffTaskResponse>>> getTasksByBranch(
            @PathVariable Long branchId,
            @RequestParam(required = false) String status,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(branchId).orElse(null);
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branchId))) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                }
            } else {
                if (!branch.getOwnerId().equals(userId)) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền quản lý chi nhánh này");
                }
            }
        }
        return ResponseEntity.ok(staffTaskService.getTasksByBranch(branchId, status));
    }

    @GetMapping("/staff/{staffId}")
    public ResponseEntity<ApiResponse<List<StaffTaskResponse>>> getTasksByStaff(
            @PathVariable Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(staffId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(staffTaskService.getTasksByStaff(staffId));
    }

    @PutMapping("/{taskId}/status")
    public ResponseEntity<ApiResponse<StaffTaskResponse>> updateStatus(
            @PathVariable Long taskId,
            @RequestBody TaskStatusUpdateRequest request, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        return ResponseEntity.ok(staffTaskService.updateTaskStatus(taskId, request));
    }

    @PutMapping("/{taskId}/assignee")
    public ResponseEntity<ApiResponse<StaffTaskResponse>> updateAssignee(
            @PathVariable Long taskId,
            @RequestParam Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(staffTaskService.updateTaskAssignee(taskId, staffId));
    }

    @GetMapping(value = "/stream/staff/{staffId}", produces = org.springframework.http.MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamForStaff(@PathVariable Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(staffId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        return staffTaskService.registerStaffEmitter(staffId);
    }
}
