package com.stayhub.api.controller;

import com.stayhub.api.service.AnalyticsRiskReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/analytics")
@RequiredArgsConstructor
public class AdminRiskAnalyticsController {

    private final AnalyticsRiskReportService riskService;

    @GetMapping("/risk")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getRiskAnalytics(
            @RequestParam(defaultValue = "7") int days) {
            
        Map<String, Object> data = riskService.getRiskAnalyticsResponse(days);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Lấy dữ liệu thống kê rủi ro thành công");
        response.put("data", data);
        
        return ResponseEntity.ok(response);
    }
}
