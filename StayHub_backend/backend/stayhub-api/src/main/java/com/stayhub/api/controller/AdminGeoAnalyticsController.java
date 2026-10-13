package com.stayhub.api.controller;

import com.stayhub.api.service.GeoAnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/analytics")
@RequiredArgsConstructor
public class AdminGeoAnalyticsController {

    private final GeoAnalyticsService geoService;

    @GetMapping("/geo-heatmap")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getGeoAnalytics() {
            
        Map<String, Object> data = geoService.getGeoAnalytics();
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Lấy dữ liệu thống kê bản đồ thành công");
        response.put("data", data);
        
        return ResponseEntity.ok(response);
    }
}
