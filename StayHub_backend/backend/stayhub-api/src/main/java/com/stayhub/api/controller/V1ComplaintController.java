package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.ComplaintRequest;
import com.stayhub.api.dto.request.ComplaintStatusUpdateRequest;
import com.stayhub.api.dto.response.ComplaintResponse;
import com.stayhub.api.service.impl.ComplaintServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@RestController
@RequestMapping("/v1/complaints")
@RequiredArgsConstructor
public class V1ComplaintController {

    private final ComplaintServiceImpl complaintService;

    @PostMapping
    public ResponseEntity<ApiResponse<ComplaintResponse>> createComplaint(
            @RequestBody ComplaintRequest request) {
        Long tenantId = (Long) org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(complaintService.createComplaint(tenantId, request));
    }

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<ComplaintResponse>>> getComplaintsByBranch(
            @PathVariable Long branchId,
            @RequestParam(required = false) String status,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                    .body(com.stayhub.api.dto.response.ApiResponse.error("Yêu cầu xác thực"));
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body(com.stayhub.api.dto.response.ApiResponse.error("Chỉ chủ nhà hoặc nhân viên mới xem được khiếu nại chi nhánh"));
        }
        
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(branchId).orElse(null);
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branchId))) {
                    return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                        .body(com.stayhub.api.dto.response.ApiResponse.error("Bạn không được phân công quản lý chi nhánh này"));
                }
            } else if (!branch.getOwnerId().equals(userId)) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body(com.stayhub.api.dto.response.ApiResponse.error("Bạn không có quyền quản lý chi nhánh này"));
            }
        }
        
        return ResponseEntity.ok(complaintService.getComplaintsByBranch(branchId, status));
    }

    @GetMapping("/tenant")
    public ResponseEntity<ApiResponse<List<ComplaintResponse>>> getComplaintsByTenant() {
        Long tenantId = (Long) org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(complaintService.getComplaintsByTenant(tenantId));
    }

    @PutMapping("/{complaintId}/status")
    public ResponseEntity<ApiResponse<ComplaintResponse>> updateStatus(
            @PathVariable Long complaintId,
            @RequestBody ComplaintStatusUpdateRequest request) {
        Long adminId = (Long) org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(complaintService.updateComplaintStatus(complaintId, adminId, request));
    }

    @GetMapping("/stream/branch/{branchId}")
    public org.springframework.web.servlet.mvc.method.annotation.SseEmitter streamForBranch(
            @PathVariable Long branchId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return null;
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) return null;
        return complaintService.registerBranchEmitter(branchId);
    }

    @GetMapping("/stream/tenant/{tenantId}")
    public org.springframework.web.servlet.mvc.method.annotation.SseEmitter streamForTenant(
            @PathVariable Long tenantId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return null;
        Long userId = (Long) auth.getPrincipal();
        // Tenant chỉ được stream của chính mình
        if (!userId.equals(tenantId)) return null;
        return complaintService.registerTenantEmitter(tenantId);
    }
}
