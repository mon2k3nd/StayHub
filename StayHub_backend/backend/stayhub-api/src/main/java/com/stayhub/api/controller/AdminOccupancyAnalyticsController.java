package com.stayhub.api.controller;

import com.stayhub.api.service.AnalyticsOccupancyReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/analytics")
@RequiredArgsConstructor
public class AdminOccupancyAnalyticsController {

    private final AnalyticsOccupancyReportService occupancyService;

    @GetMapping("/occupancy")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getOccupancyAnalytics(
            @RequestParam(defaultValue = "7") int days) {
            
        Map<String, Object> data = occupancyService.getOccupancyAnalyticsResponse(days);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Lấy dữ liệu thống kê lấp đầy thành công");
        response.put("data", data);
        
        return ResponseEntity.ok(response);
    }
}
