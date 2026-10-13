package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.AdvancedAdminAnalyticsService;
import com.stayhub.api.service.AdvancedOwnerAnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/analytics/advanced")
@RequiredArgsConstructor
public class V1AdvancedAnalyticsController {

    private final AdvancedOwnerAnalyticsService ownerAnalyticsService;
    private final AdvancedAdminAnalyticsService adminAnalyticsService;

    // --- OWNER ENDPOINTS ---
    @GetMapping("/owner/financial")
    @PreAuthorize("hasRole('OWNER')")
    public ResponseEntity<?> getOwnerFinancial(
            Authentication authentication,
            @org.springframework.web.bind.annotation.RequestParam(defaultValue = "6") int months) {
        return ResponseEntity.ok(ApiResponse.ok(ownerAnalyticsService.getFinancialAnalytics(authentication.getName(), months)));
    }

    @GetMapping("/owner/occupancy")
    @PreAuthorize("hasRole('OWNER')")
    public ResponseEntity<?> getOwnerOccupancy(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.ok(ownerAnalyticsService.getOccupancyAnalytics(authentication.getName())));
    }

    @GetMapping("/owner/ops")
    @PreAuthorize("hasRole('OWNER')")
    public ResponseEntity<?> getOwnerOps(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.ok(ownerAnalyticsService.getOpsAnalytics(authentication.getName())));
    }

    // --- ADMIN ENDPOINTS ---
    @GetMapping("/admin/saas")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminSaas(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.ok(adminAnalyticsService.getSaasAnalytics()));
    }
}
