package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Voucher;
import com.stayhub.api.service.VoucherService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/v1")
@RequiredArgsConstructor
public class VoucherController {

    private final VoucherService voucherService;

    @GetMapping("/owner/vouchers")
    public ResponseEntity<ApiResponse<List<Voucher>>> getOwnerVouchers(
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<List<Voucher>>builder().success(false).message("Yêu cầu xác thực").build());
        Long ownerId = (Long) auth.getPrincipal(); // Lấy từ token, không từ query param
        List<Voucher> vouchers = voucherService.getVouchersByOwner(ownerId);
        return ResponseEntity.ok(ApiResponse.<List<Voucher>>builder().success(true).data(vouchers).build());
    }

    @PostMapping("/owner/vouchers")
    public ResponseEntity<ApiResponse<Voucher>> createVoucher(
            @RequestBody VoucherRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Voucher>builder().success(false).message("Yêu cầu xác thực").build());
        Long ownerId = (Long) auth.getPrincipal(); // Khóa ownerId từ token
        
        Voucher v = Voucher.builder()
                .code(request.getCode())
                .discountType(Voucher.DiscountType.valueOf(request.getDiscountType()))
                .discountAmount(request.getDiscountAmount())
                .discountPercent(request.getDiscountPercent())
                .maxDiscountAmount(request.getMaxDiscountAmount())
                .monthsPerTenant(request.getMonthsPerTenant())
                .totalUsageLimit(request.getTotalUsageLimit())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .description(request.getDescription())
                .isActive(true)
                .usedCount(0)
                .applyAllRooms(request.getApplyAllRooms() != null ? request.getApplyAllRooms() : false)
                .branchId(request.getBranchId())
                .build();
                
        Voucher saved = voucherService.createVoucher(ownerId, v, request.getRoomIds());
        return ResponseEntity.ok(ApiResponse.<Voucher>builder().success(true).data(saved).build());
    }

    @PostMapping("/vouchers/validate")
    public ResponseEntity<ApiResponse<Voucher>> validateVoucher(
            @RequestParam String code,
            @RequestParam Long roomId) {
        
        Optional<Voucher> voucherOpt = voucherService.validateVoucher(code, roomId);
        
        if (voucherOpt.isPresent()) {
            return ResponseEntity.ok(ApiResponse.<Voucher>builder()
                    .success(true)
                    .data(voucherOpt.get())
                    .message("Mã giảm giá hợp lệ")
                    .build());
        } else {
            return ResponseEntity.badRequest().body(ApiResponse.<Voucher>builder()
                    .success(false)
                    .message("Mã giảm giá không hợp lệ hoặc không áp dụng cho phòng này")
                    .build());
        }
    }
}
