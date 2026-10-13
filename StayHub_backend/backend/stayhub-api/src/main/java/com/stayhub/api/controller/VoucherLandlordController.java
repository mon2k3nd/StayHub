package com.stayhub.api.controller;

import com.stayhub.api.dto.request.VoucherCreateRequest;
import com.stayhub.api.dto.response.VoucherResponse;
import com.stayhub.api.entity.Voucher;
import org.springframework.security.core.Authentication;
import com.stayhub.api.service.VoucherManagementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vouchers/landlord")
@RequiredArgsConstructor
public class VoucherLandlordController {

    private final VoucherManagementService voucherManagementService;

    @GetMapping
    public ResponseEntity<List<VoucherResponse>> getLandlordVouchers(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isOwner) return ResponseEntity.status(403).build();
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(voucherManagementService.getLandlordVouchers(userId));
    }

    @PostMapping
    public ResponseEntity<VoucherResponse> createLandlordVoucher(
            Authentication auth,
            @Valid @RequestBody VoucherCreateRequest request) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isOwner) return ResponseEntity.status(403).build();
        Long userId = (Long) auth.getPrincipal();
        VoucherResponse response = voucherManagementService.createVoucher(
                userId,
                request,
                Voucher.CreatedByRole.LANDLORD,
                Voucher.FundedBy.LANDLORD
        );
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteLandlordVoucher(
            Authentication auth,
            @PathVariable Long id) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isOwner) return ResponseEntity.status(403).build();
        Long userId = (Long) auth.getPrincipal();
        voucherManagementService.deleteLandlordVoucher(userId, id);
        return ResponseEntity.ok().build();
    }
}
