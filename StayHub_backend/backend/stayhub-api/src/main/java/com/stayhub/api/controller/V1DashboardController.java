package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.DashboardStats;
import com.stayhub.api.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/v1/dashboard")
@RequiredArgsConstructor
public class V1DashboardController {

    private final DashboardService dashboardService;

    /**
     * Thống kê tổng quan cho chủ nhà.
     * Chỉ trả data của chính chủ nhà đang đăng nhập.
     */
    @GetMapping("/owner")
    public ResponseEntity<ApiResponse<DashboardStats>> getOwnerStats(
            Authentication auth,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {

        Long ownerId = (Long) auth.getPrincipal();
        int m = month != null ? month : LocalDate.now().getMonthValue();
        int y = year != null ? year : LocalDate.now().getYear();

        DashboardStats stats = dashboardService.getOwnerStats(ownerId, m, y);
        return ResponseEntity.ok(ApiResponse.<DashboardStats>builder()
                .success(true)
                .message("Thành công!")
                .data(stats)
                .build());
    }
}
