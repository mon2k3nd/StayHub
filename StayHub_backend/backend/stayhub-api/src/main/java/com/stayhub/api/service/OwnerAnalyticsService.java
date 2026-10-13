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
public class OwnerAnalyticsService {

    public Map<String, Object> getOwnerAnalytics(Long ownerId, int days) {
        log.info("Fetching Owner Analytics for ownerId: {}, days: {}", ownerId, days);
        
        Map<String, Object> response = new HashMap<>();

        // 1. Owner Info
        Map<String, Object> ownerInfo = new HashMap<>();
        ownerInfo.put("id", ownerId);
        ownerInfo.put("fullName", "Chủ nhà #" + ownerId);
        ownerInfo.put("packageStatus", "PRO_PACKAGE");
        ownerInfo.put("trustScore", 4.8);
        response.put("ownerInfo", ownerInfo);

        // 2. ROI Summary
        Map<String, Object> roiSummary = new HashMap<>();
        roiSummary.put("totalRevenue", 150000000);
        roiSummary.put("totalRooms", 20);
        roiSummary.put("occupancyRate", 95.0);
        roiSummary.put("unpaidDebt", 0);
        response.put("roiSummary", roiSummary);

        // 3. Revenue Trend Chart
        Map<String, Object> revenueTrendChart = new HashMap<>();
        revenueTrendChart.put("minY", 0);
        revenueTrendChart.put("maxY", 50000000);
        revenueTrendChart.put("intervalY", 10000000);
        
        List<Map<String, Object>> points = new ArrayList<>();
        points.add(createPoint(1, 30000000, "Tuần 1", "30M đ"));
        points.add(createPoint(2, 35000000, "Tuần 2", "35M đ"));
        points.add(createPoint(3, 40000000, "Tuần 3", "40M đ"));
        points.add(createPoint(4, 45000000, "Tuần 4", "45M đ"));
        revenueTrendChart.put("points", points);
        response.put("revenueTrendChart", revenueTrendChart);

        // 4. Room Performance Rank
        List<Map<String, Object>> roomRanks = new ArrayList<>();
        roomRanks.add(createRoomRank("Phòng 101 - Quận 1", 15000000, "Kín"));
        roomRanks.add(createRoomRank("Phòng 202 - Quận 3", 12000000, "Kín"));
        roomRanks.add(createRoomRank("Phòng 404 - Tân Bình", 0, "Trống 15 ngày"));
        response.put("roomPerformanceRank", roomRanks);

        // 5. Actionable Insights
        List<Map<String, Object>> insights = new ArrayList<>();
        Map<String, Object> insight = new HashMap<>();
        insight.put("type", "UPSELL_OPPORTUNITY");
        insight.put("message", "Doanh thu của Chủ nhà này đang tăng trưởng 20%. Gói Pro sắp hết hạn, cơ hội để Up-sale lên gói Enterprise.");
        insight.put("actionText", "Tặng Voucher 10% Enterprise");
        insights.add(insight);
        response.put("actionableInsights", insights);

        return response;
    }

    private Map<String, Object> createPoint(int x, double y, String label, String tooltip) {
        Map<String, Object> point = new HashMap<>();
        point.put("x", x);
        point.put("y", y);
        point.put("label", label);
        point.put("tooltip", tooltip);
        return point;
    }

    private Map<String, Object> createRoomRank(String name, double revenue, String status) {
        Map<String, Object> rank = new HashMap<>();
        rank.put("roomName", name);
        rank.put("revenue", revenue);
        rank.put("status", status);
        return rank;
    }
}
