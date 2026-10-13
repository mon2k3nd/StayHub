package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.PackageSubscription;
import com.stayhub.api.entity.PlanType;
import com.stayhub.api.service.PackageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/packages")
@RequiredArgsConstructor
public class PackageController {

    private final PackageService packageService;

    /** Chủ nhà đăng ký mua gói PRO/VIP */
    @PostMapping("/subscribe")
    public ResponseEntity<ApiResponse<PackageSubscription>> subscribe(
            @RequestParam Long ownerId,
            @RequestParam PlanType packageType) {
        try {
            PackageSubscription result = packageService.subscribe(ownerId, packageType);
            return ResponseEntity.ok(ApiResponse.<PackageSubscription>builder()
                    .success(true)
                    .message("Đã gửi yêu cầu nâng cấp gói! Mã chuyển khoản: " + result.getTransferCode())
                    .data(result).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<PackageSubscription>builder().success(false).message(e.getMessage()).build());
        }
    }

    /** ADMIN: Lấy danh sách yêu cầu đang chờ kích hoạt */
    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<PackageSubscription>>> getPending() {
        return ResponseEntity.ok(ApiResponse.<List<PackageSubscription>>builder()
                .success(true).message("Thành công!")
                .data(packageService.getPending()).build());
    }

    /** ADMIN: Kích hoạt gói sau khi xác nhận tiền về */
    @PostMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<Void>> activate(@PathVariable Long id,
                                                      @RequestParam Long adminId) {
        try {
            packageService.activate(id, adminId);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true).message("Đã kích hoạt gói dịch vụ thành công!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<PackageSubscription>>> getByOwner(@PathVariable Long ownerId) {
        return ResponseEntity.ok(ApiResponse.<List<PackageSubscription>>builder()
                .success(true).message("Thành công!")
                .data(packageService.getByOwner(ownerId)).build());
    }
}
