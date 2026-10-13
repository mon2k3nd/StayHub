package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.ContractDetailResponse;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.service.ContractService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/contracts")
@RequiredArgsConstructor
public class ContractController {

    private final ContractService contractService;

    @GetMapping("/tenant/{tenantId}")
    public ResponseEntity<ApiResponse<List<ContractDetailResponse>>> getByTenant(
            @PathVariable Long tenantId,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null || !tenantId.equals(auth.getPrincipal())) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem hợp đồng của người khác");
        }
        List<ContractDetailResponse> responses = contractService.getByTenant(tenantId).stream()
                .map(c -> contractService.getContractDetail(c.getId()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(responses));
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<ContractDetailResponse>>> getByOwner(
            @PathVariable Long ownerId,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId) && !isStaff) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem hợp đồng của chủ nhà khác");
        }
        List<ContractDetailResponse> responses = contractService.getByOwner(ownerId).stream()
                .map(c -> contractService.getContractDetail(c.getId()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(responses));
    }

    @GetMapping("/room/{roomId}/active")
    public ResponseEntity<ApiResponse<Contract>> getActiveByRoom(@PathVariable Long roomId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Contract contract = contractService.getActiveByRoom(roomId);
        if (contract == null) return ResponseEntity.ok(ApiResponse.ok(null));
        
        if (!contract.getOwnerId().equals(userId) && (contract.getTenantId() == null || !contract.getTenantId().equals(userId))) {
            if (isStaff) {
                 java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                 com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(roomId).orElse(null);
                 if (room == null || assignments.stream().noneMatch(a -> a.getBranchId().equals(room.getBranchId()))) {
                     throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem hợp đồng của phòng này");
                 }
            } else {
                 throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem hợp đồng của phòng này");
            }
        }
        return ResponseEntity.ok(ApiResponse.ok(contract));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Contract>> create(@RequestBody Contract contract, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(contract.getRoomId()).orElse(null);
        if (room == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng");
        
        Long ownerId = userId;
        if (isStaff) {
             java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
             if (assignments.stream().noneMatch(a -> a.getBranchId().equals(room.getBranchId()))) {
                 throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không được phân công quản lý chi nhánh này");
             }
             ownerId = room.getOwnerId();
        } else {
             if (!room.getOwnerId().equals(userId)) {
                 throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền tạo hợp đồng cho phòng này");
             }
        }
        
        contract.setOwnerId(ownerId);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<Contract>builder()
                        .success(true)
                        .message("Tạo hợp đồng thành công!")
                        .data(contractService.create(contract))
                        .build());
    }

    @PostMapping("/offline-create")
    public ResponseEntity<ApiResponse<Contract>> offlineCreate(
            @RequestBody com.stayhub.api.dto.request.OfflineContractCreateRequest request,
            Authentication auth) {
        Long ownerId = (Long) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<Contract>builder()
                        .success(true)
                        .message("Tạo hợp đồng offline thành công!")
                        .data(contractService.offlineCreateContract(ownerId, request))
                        .build());
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Contract>> cancelOfflineContract(
            @PathVariable Long id,
            Authentication auth) {
        Long ownerId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.<Contract>builder()
                .success(true)
                .message("Đã hủy hợp đồng chờ kích hoạt!")
                .data(contractService.cancelOfflineContract(id, ownerId))
                .build());
    }


    @PostMapping(value = "/{id}/verify", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Contract>> verifyAndSign(
            @PathVariable Long id,
            @RequestParam(value = "contractImages", required = false) List<MultipartFile> contractImages,
            @RequestParam(value = "electricityMeterImage", required = false) MultipartFile electricityMeterImage,
            @RequestParam(value = "waterMeterImage", required = false) MultipartFile waterMeterImage,
            @RequestParam(value = "inspectionImages", required = false) List<MultipartFile> inspectionImages,
            @RequestParam(value = "furnitureImages", required = false) List<MultipartFile> furnitureImages,
            @RequestParam(value = "furnitureNotes", required = false) List<String> furnitureNotes,
            Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        
        try {
            Long tenantId = (Long) auth.getPrincipal();
            Contract updatedContract = contractService.verifyContract(
                    id, tenantId, contractImages, electricityMeterImage, waterMeterImage, inspectionImages, furnitureImages, furnitureNotes);
            return ResponseEntity.ok(ApiResponse.<Contract>builder()
                    .success(true)
                    .message("Nghiệm thu và ký số thành công!")
                    .data(updatedContract)
                    .build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi nghiệm thu: " + e.getMessage()));
        }
    }

    @PostMapping(value = "/{id}/offline-verify", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Contract>> offlineVerify(
            @PathVariable Long id,
            @RequestParam(value = "contractImages", required = false) List<MultipartFile> contractImages,
            @RequestParam(value = "cccdImages", required = false) List<MultipartFile> cccdImages,
            Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        
        try {
            Long ownerId = (Long) auth.getPrincipal();
            Contract updatedContract = contractService.offlineVerifyContract(id, ownerId, contractImages, cccdImages);
            return ResponseEntity.ok(ApiResponse.<Contract>builder()
                    .success(true)
                    .message("Upload và Kích hoạt hợp đồng thành công!")
                    .data(updatedContract)
                    .build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi kích hoạt hợp đồng: " + e.getMessage()));
        }
    }

    @GetMapping("/{id}/inspection-log")
    public ResponseEntity<ApiResponse<Object>> getInspectionLog(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        try {
            Long tenantId = (Long) auth.getPrincipal();
            Object log = contractService.getInspectionLog(id, tenantId);
            return ResponseEntity.ok(ApiResponse.<Object>builder()
                    .success(true)
                    .message("Lấy thông tin thành công")
                    .data(log)
                    .build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/{id}/terminate")
    public ResponseEntity<ApiResponse<Contract>> terminate(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        Long userId = (Long) auth.getPrincipal();
        // Validate ownership — delegate to service which checks ownerId/tenantId
        String reason = body.getOrDefault("reason", "Chấm dứt hợp đồng theo yêu cầu");
        return ResponseEntity.ok(ApiResponse.<Contract>builder()
                .success(true)
                .message("Đã chấm dứt hợp đồng!")
                .data(contractService.terminate(id, userId, reason))
                .build());
    }

    @PostMapping("/{id}/renew")
    public ResponseEntity<ApiResponse<Contract>> renew(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        Long userId = (Long) auth.getPrincipal();
        int months = Integer.parseInt(body.getOrDefault("months", "12"));
        return ResponseEntity.ok(ApiResponse.<Contract>builder()
                .success(true)
                .message("Gia hạn hợp đồng thành công!")
                .data(contractService.renew(id, userId, months))
                .build());
    }

    @GetMapping("/{id}/detail")
    public ResponseEntity<ApiResponse<ContractDetailResponse>> getContractDetail(
            @PathVariable Long id,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        try {
            Long userId = (Long) auth.getPrincipal();
            boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
            boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
            ContractDetailResponse detail = contractService.getContractDetail(id);
            // Verify access: must be contract owner, tenant, or staff
            boolean isTenant = detail.getTenantId() != null && detail.getTenantId().equals(userId);
            boolean isContractOwner = isOwner || isStaff;
            if (!isTenant && !isContractOwner) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.error("Bạn không có quyền xem hợp đồng này"));
            }
            return ResponseEntity.ok(ApiResponse.<ContractDetailResponse>builder()
                    .success(true)
                    .message("Lấy thông tin hợp đồng thành công")
                    .data(detail)
                    .build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/{id}/tenant-sign")
    public ResponseEntity<ApiResponse<Contract>> tenantSignContract(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        try {
            Long tenantId = (Long) auth.getPrincipal();
            String signature = body.get("signature");
            String handoverCondition = body.get("handoverCondition");
            
            Contract signed = contractService.tenantSignContract(id, tenantId, signature, handoverCondition);
            return ResponseEntity.ok(ApiResponse.<Contract>builder()
                    .success(true)
                    .message("Ký hợp đồng thành công! Tiếp tục nghiệm thu phòng.")
                    .data(signed)
                    .build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi ký hợp đồng: " + e.getMessage()));
        }
    }

    /**
     * Thanh lý hợp đồng: Chủ nhà nhập thông tin hư hỏng → tính khấu trừ → hoàn cọc.
     * Body: { damageDeduction: 500000, damageNote: "Vỡ gương, hỏng điều hòa" }
     * Response: { totalDeposit, damageDeduction, depositRefund, damageNote, message }
     */
    @PostMapping("/{id}/liquidate")
    public ResponseEntity<ApiResponse<Map<String, Object>>> liquidate(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.error("Chỉ chủ nhà hoặc nhân viên mới có quyền thanh lý hợp đồng"));
        }
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Thanh lý hợp đồng thành công!")
                .data(contractService.liquidate(id, body))
                .build());
    }

    /**
     * Checkout nhanh: Chủ nhà xác nhận trả phòng + ghi nhận hư hỏng + hoàn cọc trong 1 API.
     * Body: { damageDeduction: 0, damageNote: "", reason: "Khách chủ động trả phòng" }
     */
    @PostMapping("/{id}/checkout")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkout(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.error("Chỉ chủ nhà hoặc nhân viên mới có quyền thực hiện checkout"));
        }
        // Gộp terminate + liquidate: đưa tất cả thông tin vào liquidate (status → LIQUIDATED)
        Map<String, Object> liquidateData = new java.util.HashMap<>(body);
        Map<String, Object> result = contractService.liquidate(id, liquidateData);
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Checkout thành công! Phòng đã được giải phóng.")
                .data(result)
                .build());
    }
}
