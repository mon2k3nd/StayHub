package com.stayhub.api.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class GeoAnalyticsService {

    public Map<String, Object> getGeoAnalytics() {
        log.info("Fetching Geo-Spatial Analytics (Heatmap)");
        
        Map<String, Object> response = new HashMap<>();

        // 1. Summary
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalRegions", 5);
        summary.put("hottestRegion", "Quận Gò Vấp, TP.HCM");
        summary.put("coldestRegion", "Quận Tân Bình, TP.HCM");
        response.put("summary", summary);

        // 2. Regions Data
        List<Map<String, Object>> regions = new ArrayList<>();
        regions.add(createRegion("Quận Gò Vấp, TP.HCM", 850, 92.5, 3500000, "VERY HOT", 10.8386, 106.6659));
        regions.add(createRegion("Quận 1, TP.HCM", 210, 85.0, 6500000, "HOT", 10.7769, 106.7009));
        regions.add(createRegion("Quận 7, TP.HCM", 450, 75.0, 5000000, "WARM", 10.7339, 106.7215));
        regions.add(createRegion("Cầu Giấy, Hà Nội", 120, 60.0, 4500000, "NORMAL", 21.0285, 105.7963));
        regions.add(createRegion("Quận Tân Bình, TP.HCM", 100, 40.0, 4000000, "COLD", 10.8015, 106.6526));
        response.put("regions", regions);

        // 3. Actionable Insights
        List<Map<String, Object>> insights = new ArrayList<>();
        Map<String, Object> insight = new HashMap<>();
        insight.put("type", "GEO_MARKETING_ALERT");
        insight.put("message", "Quận Tân Bình đang có tỷ lệ lấp đầy rất thấp (40%). Đề xuất mở chiến dịch ưu đãi phí môi giới tại khu vực này để thu hút Khách thuê.");
        insight.put("actionText", "Mở Chiến dịch Tân Bình");
        insights.add(insight);
        response.put("actionableInsights", insights);

        return response;
    }

    private Map<String, Object> createRegion(String name, int roomCount, double occupancyRate, double averagePrice, String status, double lat, double lng) {
        Map<String, Object> region = new HashMap<>();
        region.put("name", name);
        region.put("roomCount", roomCount);
        region.put("occupancyRate", occupancyRate);
        region.put("averagePrice", averagePrice);
        region.put("status", status);
        
        Map<String, Double> coordinates = new HashMap<>();
        coordinates.put("lat", lat);
        coordinates.put("lng", lng);
        region.put("coordinates", coordinates);
        
        return region;
    }
}
