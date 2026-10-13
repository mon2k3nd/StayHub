package com.stayhub.api.controller;

import com.stayhub.api.service.OwnerAnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/analytics")
@RequiredArgsConstructor
public class AdminOwnerAnalyticsController {

    private final OwnerAnalyticsService ownerAnalyticsService;

    @GetMapping("/owners/{ownerId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getOwnerAnalytics(
            @PathVariable Long ownerId,
            @RequestParam(defaultValue = "30") int days) {
            
        Map<String, Object> data = ownerAnalyticsService.getOwnerAnalytics(ownerId, days);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Lấy dữ liệu thống kê chủ nhà thành công");
        response.put("data", data);
        
        return ResponseEntity.ok(response);
    }
}
