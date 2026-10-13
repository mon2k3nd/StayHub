package com.stayhub.api.controller;

import com.stayhub.api.entity.ServicePool;
import com.stayhub.api.service.ServicePoolService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/service-pools")
@RequiredArgsConstructor
public class ServicePoolController {

    private final ServicePoolService servicePoolService;

    /**
     * Tao moi 1 Nhom Dich Vu dung chung (Landlord only)
     * POST /api/service-pools
     * Body: { branchId, name, serviceType, allocationMethod, price }
     */
    @PostMapping
    public ResponseEntity<ServicePool> createPool(@RequestBody ServicePool pool, org.springframework.security.core.Authentication auth) {
        verifyBranchAccess(pool.getBranchId(), auth);
        return ResponseEntity.ok(servicePoolService.createPool(pool));
    }

    @PutMapping("/{poolId}/amount")
    public ResponseEntity<ServicePool> updatePoolAmount(
            @PathVariable Long poolId,
            @RequestParam Double total,
            org.springframework.security.core.Authentication auth) {
        ServicePool pool = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ServicePoolRepository.class).findById(poolId).orElseThrow(() -> new RuntimeException("Pool not found"));
        verifyBranchAccess(pool.getBranchId(), auth);
        return ResponseEntity.ok(servicePoolService.updatePoolAmount(poolId, total));
    }

    @PostMapping("/{poolId}/rooms/{roomId}")
    public ResponseEntity<Void> assignRoom(
            @PathVariable Long poolId,
            @PathVariable Long roomId,
            org.springframework.security.core.Authentication auth) {
        ServicePool pool = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ServicePoolRepository.class).findById(poolId).orElseThrow(() -> new RuntimeException("Pool not found"));
        verifyBranchAccess(pool.getBranchId(), auth);
        servicePoolService.assignRoomToPool(roomId, poolId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{poolId}/rooms/{roomId}")
    public ResponseEntity<Void> removeRoom(
            @PathVariable Long poolId,
            @PathVariable Long roomId,
            org.springframework.security.core.Authentication auth) {
        ServicePool pool = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ServicePoolRepository.class).findById(poolId).orElseThrow(() -> new RuntimeException("Pool not found"));
        verifyBranchAccess(pool.getBranchId(), auth);
        servicePoolService.removeRoomFromPool(roomId, poolId);
        return ResponseEntity.ok().build();
    }
    
    private void verifyBranchAccess(Long branchId, org.springframework.security.core.Authentication auth) {
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
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền quản lý dịch vụ của chi nhánh này");
                }
            }
        }
    }

    /**
     * Lay danh sach Pool cua 1 Toa nha
     * GET /api/service-pools/branch/{branchId}
     */
    @GetMapping("/branch/{branchId}")
    public ResponseEntity<List<ServicePool>> getByBranch(@PathVariable Long branchId) {
        return ResponseEntity.ok(servicePoolService.getPoolsByBranch(branchId));
    }

    /**
     * Lay danh sach Pool cua 1 Phong (Phong dang tham gia Pool nao)
     * GET /api/service-pools/room/{roomId}
     */
    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<ServicePool>> getByRoom(@PathVariable Long roomId) {
        return ResponseEntity.ok(servicePoolService.getPoolsByRoom(roomId));
    }

    /**
     * Tinh toan phi dich vu chung thang nay cho 1 Phong
     * GET /api/service-pools/calculate/{roomId}
     * Response: { "Dien chung Tang 2": 100000.0, "Dien hanh lang Toa": 60000.0 }
     */
    @GetMapping("/calculate/{roomId}")
    public ResponseEntity<List<Map<String, Object>>> calculateForRoom(@PathVariable Long roomId) {
        return ResponseEntity.ok(servicePoolService.calculateAllSharedServicesForRoom(roomId));
    }
}
