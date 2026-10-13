package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.TaxReportResponse;
import com.stayhub.api.service.TaxService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/taxes")
@RequiredArgsConstructor
@CrossOrigin("*")
public class TaxController {

    private final TaxService taxService;

    @GetMapping("/report/{ownerId}")
    public ResponseEntity<ApiResponse<TaxReportResponse>> getTaxReport(
            @PathVariable Long ownerId,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            org.springframework.security.core.Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.<TaxReportResponse>builder().success(false).message("Yêu cầu xác thực").build());
        }
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
            return ResponseEntity.status(403).body(ApiResponse.<TaxReportResponse>builder().success(false).message("Bạn không có quyền xem báo cáo thuế này").build());
        }
        
        int m = month != null ? month : LocalDate.now().getMonthValue();
        int y = year != null ? year : LocalDate.now().getYear();

        TaxReportResponse report = taxService.calculateTaxForOwner(ownerId, m, y);
        return ResponseEntity.ok(ApiResponse.<TaxReportResponse>builder()
                .success(true).message("Lấy báo cáo thuế thành công")
                .data(report).build());
    }
}
