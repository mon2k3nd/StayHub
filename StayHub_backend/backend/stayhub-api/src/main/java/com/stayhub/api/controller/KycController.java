package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.KycRequest;
import com.stayhub.api.service.KycService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/kyc")
@RequiredArgsConstructor
public class KycController {

    private final KycService kycService;

    /** Tenant gửi yêu cầu nâng cấp lên OWNER */
    @PostMapping("/request")
    public ResponseEntity<ApiResponse<KycRequest>> submitRequest(
            @RequestParam Long userId,
            @RequestParam String branchName,
            @RequestParam String businessAddress,
            @RequestParam(required = false) MultipartFile cccdFront,
            @RequestParam(required = false) MultipartFile cccdBack,
            @RequestParam(required = false) MultipartFile businessLicense) {
        try {
            KycRequest result = kycService.submitRequest(userId, branchName, businessAddress,
                    cccdFront, cccdBack, businessLicense);
            return ResponseEntity.ok(ApiResponse.<KycRequest>builder()
                    .success(true).message("Yêu cầu đã được gửi. Vui lòng chờ ADMIN xét duyệt!")
                    .data(result).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<KycRequest>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** ADMIN: Lấy danh sách yêu cầu đang chờ */
    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<KycRequest>>> getPending() {
        return ResponseEntity.ok(ApiResponse.<List<KycRequest>>builder()
                .success(true).message("Thành công!")
                .data(kycService.getPending()).build());
    }

    /** ADMIN: Phê duyệt */
    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<Void>> approve(@PathVariable Long id) {
        try {
            kycService.approve(id);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true).message("Đã phê duyệt tài khoản Chủ nhà!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** ADMIN: Từ chối */
    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> reject(@PathVariable Long id,
                                                    @RequestBody Map<String, String> body) {
        try {
            String reason = body.getOrDefault("reason", "Hồ sơ không hợp lệ");
            kycService.reject(id, reason);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true).message("Đã từ chối yêu cầu!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }
}
