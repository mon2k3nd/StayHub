package com.stayhub.api.controller;

import com.stayhub.api.dto.request.VoucherCreateRequest;
import com.stayhub.api.dto.response.VoucherResponse;
import com.stayhub.api.entity.Voucher;
import org.springframework.security.core.Authentication;
import com.stayhub.api.service.VoucherManagementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vouchers/admin")
@RequiredArgsConstructor
public class VoucherAdminController {

    private final VoucherManagementService voucherManagementService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<VoucherResponse>> getAllAdminVouchers(Pageable pageable) {
        return ResponseEntity.ok(voucherManagementService.getAllAdminVouchers(pageable));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VoucherResponse> createAdminVoucher(
            Authentication auth,
            @Valid @RequestBody VoucherCreateRequest request) {
        Long userId = (Long) auth.getPrincipal();
        // Force FundedBy to ADMIN and CreatedBy to ADMIN
        VoucherResponse response = voucherManagementService.createVoucher(
                userId, 
                request, 
                Voucher.CreatedByRole.ADMIN, 
                Voucher.FundedBy.ADMIN
        );
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> toggleVoucherStatus(
            @PathVariable Long id,
            @RequestParam boolean isActive) {
        voucherManagementService.toggleVoucherStatus(id, isActive);
        return ResponseEntity.ok().build();
    }
}
