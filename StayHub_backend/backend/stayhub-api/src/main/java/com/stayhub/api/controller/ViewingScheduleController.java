package com.stayhub.api.controller;

import com.stayhub.api.entity.RequestStatus;
import com.stayhub.api.entity.ViewingSchedule;
import com.stayhub.api.service.ViewingScheduleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/viewing-schedules")
public class ViewingScheduleController {

    @Autowired
    private ViewingScheduleService service;

    @PostMapping
    public ResponseEntity<ViewingSchedule> createSchedule(
            @RequestBody ViewingSchedule schedule,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        Long userId = (Long) auth.getPrincipal();
        // Tenant đặt lịch: gán tenantId từ token, không để frontend truyền tuỳ ý
        schedule.setTenantId(userId);
        return ResponseEntity.ok(service.createSchedule(schedule));
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<List<ViewingSchedule>> getSchedulesForOwner(
            @PathVariable Long ownerId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId) && !isStaff) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(service.getSchedulesForOwner(ownerId));
    }

    @GetMapping("/tenant/{tenantId}")
    public ResponseEntity<List<ViewingSchedule>> getSchedulesForTenant(
            @PathVariable Long tenantId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(tenantId)) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(service.getSchedulesForTenant(tenantId));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ViewingSchedule> updateStatus(
            @PathVariable Long id,
            @RequestParam RequestStatus status,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        Long userId = (Long) auth.getPrincipal();
        ViewingSchedule schedule = service.getById(id);

        // BUGFIX (security/logic): trước đây chỉ kiểm tra ROLE_OWNER — nghĩa là
        // BẤT KỲ chủ nhà nào cũng duyệt/từ chối được lịch của chủ nhà khác.
        // Đồng thời tenant cũng có thể tự đặt status = APPROVED cho lịch của
        // mình, phá vỡ luồng "chủ nhà duyệt lịch".
        boolean isOwnerOfSchedule =
                schedule.getOwnerId() != null && schedule.getOwnerId().equals(userId);
        boolean isTenantOfSchedule =
                schedule.getTenantId() != null && schedule.getTenantId().equals(userId);
        boolean isStaff = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));

        if (!isOwnerOfSchedule && !isTenantOfSchedule && !isStaff) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }

        // Tenant chỉ được phép HUỶ lịch của chính mình (REJECTED).
        // Việc duyệt (APPROVED / APPROVED_WAITING_HANDOVER / COMPLETED) chỉ
        // chủ nhà sở hữu lịch hoặc staff mới được thực hiện.
        if (isTenantOfSchedule && !isOwnerOfSchedule && !isStaff
                && status != RequestStatus.REJECTED) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }

        return ResponseEntity.ok(service.updateStatus(id, status));
    }
}
