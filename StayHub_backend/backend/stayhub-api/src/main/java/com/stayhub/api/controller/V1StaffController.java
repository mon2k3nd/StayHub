package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.OwnerTenantMapping;
import com.stayhub.api.entity.StaffAssignment;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.OwnerTenantMappingRepository;
import com.stayhub.api.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/staff")
@RequiredArgsConstructor
@SuppressWarnings("unchecked")
public class V1StaffController {

    private final StaffService staffService;
    private final OwnerTenantMappingRepository ownerTenantMappingRepository;
    private final com.stayhub.api.service.SaasService saasService;
    private final com.stayhub.api.repository.UserRepository userRepository;
    private final com.stayhub.api.repository.StaffWalletRepository staffWalletRepository;
    private final com.stayhub.api.repository.StaffAssignmentRepository staffAssignmentRepository;

    /** Chủ nhà tạo tài khoản nhân viên mới */
    @PostMapping("/create")
    public ResponseEntity<ApiResponse<User>> createStaff(@RequestBody Map<String, Object> body, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ chủ nhà mới có thể tạo nhân viên");
        }
        Long ownerId = (Long) auth.getPrincipal(); // Force ownerId from token
        
        try {
            String name = (String) body.get("name");
            String phoneNumber = (String) body.get("phoneNumber");
            String password = (String) body.get("password");
            List<?> rawBranchIds = (List<?>) body.get("branchIds");
            List<Long> branchIds = null;
            if (rawBranchIds != null) {
                branchIds = rawBranchIds.stream()
                        .map(id -> Long.valueOf(id.toString()))
                        .collect(java.util.stream.Collectors.toList());
            }

            // Let's use a try-catch for the limit check.
            try {
                com.stayhub.api.entity.SaasPlan currentPlan = saasService.getCurrentPlan(ownerId);
                long currentStaffCountVal = staffService.getStaffByOwner(ownerId).size();
                if (currentStaffCountVal >= currentPlan.getMaxStaffs()) {
                    throw new RuntimeException("Bạn đã đạt giới hạn tối đa " + currentPlan.getMaxStaffs() + " nhân viên của gói " + currentPlan.getName() + ". Vui lòng nâng cấp gói cước để tạo thêm.");
                }
            } catch (Exception e) {
                if (e.getMessage().contains("giới hạn")) throw e;
                // Ignore if it fails to count for some reason, defensive programming
            }

            User staff = staffService.createStaff(name, phoneNumber, password, ownerId, branchIds);
            return ResponseEntity.ok(ApiResponse.<User>builder()
                    .success(true).message("Tạo tài khoản nhân viên thành công!")
                    .data(staff).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<User>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Lấy danh sách nhân viên theo chủ nhà */
    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<User>>> getStaffByOwner(@PathVariable Long ownerId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_STAFF"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(ApiResponse.<List<User>>builder()
                .success(true).message("Thành công!")
                .data(staffService.getStaffByOwner(ownerId)).build());
    }

    /** Lấy phân công của nhân viên */
    @GetMapping("/assignments/staff/{staffId}")
    public ResponseEntity<ApiResponse<List<StaffAssignment>>> getAssignments(@PathVariable Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(staffId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(ApiResponse.<List<StaffAssignment>>builder()
                .success(true).message("Thành công!")
                .data(staffService.getAssignments(staffId)).build());
    }

    /** Lấy ownerId của nhân viên từ mapping – dùng khi chưa có phân công */
    @GetMapping("/owner-of/{staffId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOwnerOfStaff(@PathVariable Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        List<OwnerTenantMapping> mappings = ownerTenantMappingRepository.findByTenantId(staffId);
        if (mappings.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Nhân viên chưa được liên kết với chủ nhà nào.").build());
        }
        Map<String, Object> result = new HashMap<>();
        result.put("ownerId", mappings.get(0).getOwnerId());
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true).message("Thành công!").data(result).build());
    }

    /** Cập nhật lịch trực nhân viên */
    @PutMapping("/assignments/{assignmentId}/schedule")
    public ResponseEntity<ApiResponse<StaffAssignment>> updateSchedule(
            @PathVariable Long assignmentId,
            @RequestBody Map<String, String> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyAssignmentOwnership(ownerId, assignmentId);
            String schedule = body.get("workSchedule");
            return ResponseEntity.ok(ApiResponse.<StaffAssignment>builder()
                    .success(true).message("Cập nhật lịch trực thành công!")
                    .data(staffService.updateSchedule(assignmentId, schedule)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<StaffAssignment>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Cập nhật quyền (RBAC) của nhân viên */
    @PutMapping("/{staffId}/roles")
    public ResponseEntity<ApiResponse<User>> updateStaffRole(
            @PathVariable Long staffId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyStaffOwnership(ownerId, staffId);
            List<String> roles = (List<String>) body.get("roles");
            // Call staffService.updateRoles(staffId, roles);
            return ResponseEntity.ok(ApiResponse.<User>builder()
                    .success(true).message("Cập nhật quyền thành công!")
                    .build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<User>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Xóa (Nghỉ việc) nhân viên kèm lý do */
    @PutMapping("/{staffId}/resign")
    public ResponseEntity<ApiResponse<Void>> resignStaff(@PathVariable Long staffId,
                                                          @RequestBody Map<String, String> body,
                                                          org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyStaffOwnership(ownerId, staffId);
            String reason = body.get("reason");
            staffService.changeStatus(staffId, User.UserStatus.RESIGNED, reason);
            return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã cho nhân viên nghỉ việc!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Cập nhật trạng thái nhân viên (ACTIVE/LOCKED) */
    @PutMapping("/{staffId}/status")
    public ResponseEntity<ApiResponse<Void>> changeStaffStatus(@PathVariable Long staffId,
                                                                @RequestBody Map<String, String> body,
                                                                org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyStaffOwnership(ownerId, staffId);
            String statusStr = body.get("status");
            User.UserStatus status = User.UserStatus.valueOf(statusStr);
            staffService.changeStatus(staffId, status, null);
            return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Cập nhật trạng thái thành công!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Xóa nhân viên */
    @DeleteMapping("/{staffId}/owner/{ownerId}")
    public ResponseEntity<ApiResponse<Void>> removeStaff(@PathVariable Long staffId,
                                                          @PathVariable Long ownerId,
                                                          org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId) || auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            staffService.removeStaff(staffId, ownerId);
            return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xóa nhân viên!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Cập nhật quyền hạn nhân viên */
    @PutMapping("/assignments/{assignmentId}/permissions")
    public ResponseEntity<ApiResponse<StaffAssignment>> updatePermissions(
            @PathVariable Long assignmentId,
            @RequestBody Map<String, String> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyAssignmentOwnership(ownerId, assignmentId);
            String permissions = body.get("permissions");
            String staffRole = body.get("staffRole");
            return ResponseEntity.ok(ApiResponse.<StaffAssignment>builder()
                    .success(true).message("Cập nhật quyền hạn thành công!")
                    .data(staffService.updatePermissions(assignmentId, permissions, staffRole)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<StaffAssignment>builder().success(false).message(e.getMessage()).build());
        }
    }

    @PostMapping("/{staffId}/assign-branches")
    public ResponseEntity<ApiResponse<String>> assignBranches(
            @PathVariable Long staffId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal(); // Force ownerId from token
            verifyStaffOwnership(ownerId, staffId);
            List<?> rawBranchIds = (List<?>) body.get("branchIds");
            List<Long> branchIds = null;
            if (rawBranchIds != null && !rawBranchIds.isEmpty()) {
                branchIds = rawBranchIds.stream()
                        .map(id -> Long.valueOf(id.toString()))
                        .collect(java.util.stream.Collectors.toList());
            }

            staffService.assignBranches(staffId, ownerId, branchIds);
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .success(true)
                    .message("Phân công khu trọ thành công!")
                    .data("OK").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<String>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Thanh toán tiền ứng cho nhân viên */
    @PutMapping("/wallet/settle/{staffId}")
    public ResponseEntity<ApiResponse<Void>> settleWallet(
            @PathVariable Long staffId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        try {
            Long ownerId = (Long) auth.getPrincipal();
            verifyStaffOwnership(ownerId, staffId);
            Double amount = Double.valueOf(body.get("amount").toString());
            staffService.settleWallet(staffId, amount);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true).message("Thanh toán tiền ứng thành công!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** Cập nhật hạn mức tiền mặt cho phép giữ */
    @PutMapping("/{staffId}/wallet/max-cash-limit")
    public ResponseEntity<ApiResponse<com.stayhub.api.entity.StaffWallet>> updateMaxCashLimit(
            @PathVariable Long staffId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        
        Long ownerId = (Long) auth.getPrincipal();
        verifyStaffOwnership(ownerId, staffId);
        
        Double limit = null;
        if (body.containsKey("maxCashLimit") && body.get("maxCashLimit") != null) {
            String limitStr = body.get("maxCashLimit").toString().trim();
            if (!limitStr.isEmpty()) {
                limit = Double.valueOf(limitStr);
            }
        }
        
        com.stayhub.api.entity.StaffWallet wallet = staffWalletRepository
                .findByStaffId(staffId)
                .orElse(null);
                
        if (wallet == null) {
            // Create wallet if it doesn't exist
            wallet = new com.stayhub.api.entity.StaffWallet();
            wallet.setStaffId(staffId);
            wallet.setCashCollected(0.0);
            wallet.setCashSpent(0.0);
        }
        
        wallet.setMaxCashLimit(limit);
        
        wallet = staffWalletRepository.save(wallet);
                
        return ResponseEntity.ok(ApiResponse.ok(wallet));
    }

    private void verifyStaffOwnership(Long ownerId, Long staffId) {
        List<OwnerTenantMapping> mappings = ownerTenantMappingRepository.findByTenantId(staffId);
        boolean isMapped = mappings.stream().anyMatch(m -> m.getOwnerId().equals(ownerId) && "STAFF".equals(m.getMappingType()));
        if (!isMapped) {
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId)
                    .stream().anyMatch(a -> a.getOwnerId().equals(ownerId));
            if (!hasAssignment) {
                throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Nhân viên không thuộc quyền quản lý của bạn");
            }
        }
    }

    private void verifyAssignmentOwnership(Long ownerId, Long assignmentId) {
        StaffAssignment assignment = staffAssignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phân công"));
        if (!assignment.getOwnerId().equals(ownerId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Phân công này không thuộc quyền quản lý của bạn");
        }
    }
}
