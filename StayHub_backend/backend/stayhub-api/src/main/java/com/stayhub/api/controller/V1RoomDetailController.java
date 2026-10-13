package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.RoomDevice;
import com.stayhub.api.entity.RoomHandover;
import com.stayhub.api.entity.RoomServiceConfig;
import com.stayhub.api.repository.RoomDeviceRepository;
import com.stayhub.api.repository.RoomHandoverRepository;
import com.stayhub.api.repository.RoomServiceConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * V1 REST API cho các thực thể mở rộng của Phòng:
 *  - Thiết bị IoT (RoomDevice)
 *  - Biên bản bàn giao (RoomHandover)
 *  - Cấu hình dịch vụ (RoomServiceConfig)
 */
@RestController
@RequestMapping("/v1/rooms/{roomId}")
@RequiredArgsConstructor
public class V1RoomDetailController {

    private final RoomDeviceRepository deviceRepo;
    private final RoomHandoverRepository handoverRepo;
    private final RoomServiceConfigRepository serviceConfigRepo;

    // ── IoT Devices ─────────────────────────────────────────────
    @GetMapping("/devices")
    public ResponseEntity<ApiResponse<List<RoomDevice>>> getDevices(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        return ResponseEntity.ok(ApiResponse.<List<RoomDevice>>builder()
                .success(true).message("Thành công")
                .data(deviceRepo.findByRoomId(roomId)).build());
    }

    @PostMapping("/devices")
    public ResponseEntity<ApiResponse<RoomDevice>> addDevice(
            @PathVariable Long roomId, @RequestBody RoomDevice device, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        device.setRoomId(roomId);
        return ResponseEntity.ok(ApiResponse.<RoomDevice>builder()
                .success(true).message("Đã thêm thiết bị")
                .data(deviceRepo.save(device)).build());
    }

    @PutMapping("/devices/{deviceId}")
    public ResponseEntity<ApiResponse<RoomDevice>> updateDevice(
            @PathVariable Long roomId,
            @PathVariable Long deviceId,
            @RequestBody RoomDevice updated,
            org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        return deviceRepo.findById(deviceId).map(existing -> {
            existing.setDeviceType(updated.getDeviceType());
            existing.setIpOrMacAddress(updated.getIpOrMacAddress());
            existing.setApiToken(updated.getApiToken());
            existing.setLastRecordedValue(updated.getLastRecordedValue());
            return ResponseEntity.ok(ApiResponse.<RoomDevice>builder()
                    .success(true).message("Đã cập nhật thiết bị")
                    .data(deviceRepo.save(existing)).build());
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/devices/{deviceId}")
    public ResponseEntity<ApiResponse<Void>> removeDevice(@PathVariable Long roomId, @PathVariable Long deviceId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        deviceRepo.deleteById(deviceId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true).message("Đã xóa thiết bị").build());
    }

    // ── Handover / Biên bản bàn giao ────────────────────────────
    @GetMapping("/handovers")
    public ResponseEntity<ApiResponse<List<RoomHandover>>> getHandovers(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        return ResponseEntity.ok(ApiResponse.<List<RoomHandover>>builder()
                .success(true).message("Thành công")
                .data(handoverRepo.findByRoomId(roomId)).build());
    }

    @PostMapping("/handovers")
    public ResponseEntity<ApiResponse<RoomHandover>> createHandover(
            @PathVariable Long roomId, @RequestBody RoomHandover handover, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        handover.setRoomId(roomId);
        return ResponseEntity.ok(ApiResponse.<RoomHandover>builder()
                .success(true).message("Đã lưu biên bản bàn giao")
                .data(handoverRepo.save(handover)).build());
    }

    // ── Service Configs / Cấu hình dịch vụ ──────────────────────
    @GetMapping("/service-configs")
    public ResponseEntity<ApiResponse<List<RoomServiceConfig>>> getServiceConfigs(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        return ResponseEntity.ok(ApiResponse.<List<RoomServiceConfig>>builder()
                .success(true).message("Thành công")
                .data(serviceConfigRepo.findByRoomId(roomId)).build());
    }

    @PostMapping("/service-configs")
    public ResponseEntity<ApiResponse<RoomServiceConfig>> addServiceConfig(
            @PathVariable Long roomId, @RequestBody RoomServiceConfig config, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        config.setRoomId(roomId);
        return ResponseEntity.ok(ApiResponse.<RoomServiceConfig>builder()
                .success(true).message("Đã lưu cấu hình dịch vụ")
                .data(serviceConfigRepo.save(config)).build());
    }

    private void verifyRoomAccess(Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(roomId).orElse(null);
        if (room != null) {
            com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(room.getBranchId()).orElse(null);
            if (branch != null) {
                if (isStaff) {
                    java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                    if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branch.getId()))) {
                        throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                    }
                } else {
                    if (!branch.getOwnerId().equals(userId)) {
                        throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền quản lý phòng này");
                    }
                }
            }
        }
    }

    @DeleteMapping("/service-configs/{configId}")
    public ResponseEntity<ApiResponse<Void>> removeServiceConfig(@PathVariable Long roomId, @PathVariable Long configId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        serviceConfigRepo.deleteById(configId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true).message("Đã xóa cấu hình dịch vụ").build());
    }
}
