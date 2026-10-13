package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.RoomAsset;
import com.stayhub.api.service.RoomAssetService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/assets")
@RequiredArgsConstructor
public class RoomAssetController {

    private final RoomAssetService roomAssetService;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<List<RoomAsset>>> getByRoom(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        verifyRoomAccess(roomId, auth);
        return ResponseEntity.ok(ApiResponse.<List<RoomAsset>>builder()
                .success(true).message("Thành công!")
                .data(roomAssetService.getByRoom(roomId)).build());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RoomAsset>> create(@RequestBody RoomAsset asset, org.springframework.security.core.Authentication auth) {
        try {
            verifyRoomAccess(asset.getRoomId(), auth);
            return ResponseEntity.ok(ApiResponse.<RoomAsset>builder()
                    .success(true).message("Thêm tài sản thành công!")
                    .data(roomAssetService.create(asset)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<RoomAsset>builder().success(false).message(e.getMessage()).build());
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RoomAsset>> update(@PathVariable Long id,
                                                          @RequestBody RoomAsset asset,
                                                          org.springframework.security.core.Authentication auth) {
        try {
            RoomAsset existingAsset = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomAssetRepository.class).findById(id).orElseThrow(() -> new RuntimeException("Asset not found"));
            verifyRoomAccess(existingAsset.getRoomId(), auth);
            return ResponseEntity.ok(ApiResponse.<RoomAsset>builder()
                    .success(true).message("Cập nhật tài sản thành công!")
                    .data(roomAssetService.update(id, asset)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<RoomAsset>builder().success(false).message(e.getMessage()).build());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        RoomAsset existingAsset = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomAssetRepository.class).findById(id).orElseThrow(() -> new RuntimeException("Asset not found"));
        verifyRoomAccess(existingAsset.getRoomId(), auth);
        roomAssetService.delete(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xóa tài sản!").build());
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
                        throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền quản lý tài sản của chi nhánh này");
                    }
                }
            }
        }
    }
}
