package com.stayhub.api.controller;

import com.stayhub.api.dto.ChecklistItemDto;
import com.stayhub.api.dto.HousekeepingTaskDto;
import com.stayhub.api.service.HousekeepingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/staff/housekeeping")
@RequiredArgsConstructor
public class HousekeepingController {

    private final HousekeepingService housekeepingService;

    @GetMapping("/tasks")
    public ResponseEntity<Map<String, Object>> getTasks(@RequestParam Long branchId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
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

        List<HousekeepingTaskDto> tasks = housekeepingService.getTasksByBranch(branchId);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", tasks
        ));
    }

    @PutMapping("/tasks/{id}/status")
    public ResponseEntity<Map<String, Object>> updateTaskStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            org.springframework.security.core.Authentication auth) {
        verifyTaskAccess(id, auth);
        String status = body.get("status");
        HousekeepingTaskDto updatedTask = housekeepingService.updateTaskStatus(id, status);
        return ResponseEntity.ok(Map.of("success", true, "data", updatedTask));
    }

    @PutMapping("/tasks/{id}/checklist")
    public ResponseEntity<Map<String, Object>> updateChecklist(
            @PathVariable Long id,
            @RequestBody List<ChecklistItemDto> checklist,
            org.springframework.security.core.Authentication auth) {
        verifyTaskAccess(id, auth);
        HousekeepingTaskDto updatedTask = housekeepingService.updateChecklist(id, checklist);
        return ResponseEntity.ok(Map.of("success", true, "data", updatedTask));
    }
    
    private void verifyTaskAccess(Long taskId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.HousekeepingTask task = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.HousekeepingTaskRepository.class).findById(taskId).orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy task"));
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(task.getBranchId()).orElse(null);
        
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branch.getId()))) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                }
            } else {
                if (!branch.getOwnerId().equals(userId)) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền quản lý chi nhánh này");
                }
            }
        }
    }
}
