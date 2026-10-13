package com.stayhub.api.service;

import com.stayhub.api.entity.AnalyticsFinancialReport;
import com.stayhub.api.repository.AnalyticsFinancialReportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AnalyticsFinancialReportService {

    private final AnalyticsFinancialReportRepository repository;
    // Inject other repositories like BillRepository, SubscriptionRepository here later for actual ETL
    
    @Transactional
    public void generateReportForDate(LocalDate date) {
        log.info("Starting ETL process for AnalyticsFinancialReport for date: {}", date);
        
        // 1. Phòng thủ trùng lặp Cron Job: Kiểm tra xem đã chốt sổ chưa
        Optional<AnalyticsFinancialReport> existingOpt = repository.findByReportDate(date);
        AnalyticsFinancialReport report = existingOpt.orElseGet(() -> 
            AnalyticsFinancialReport.builder()
                .reportDate(date)
                .reportMonth(date.getMonthValue())
                .reportYear(date.getYear())
                .build()
        );
        
        if (Boolean.TRUE.equals(report.getIsFinalized())) {
            log.warn("Report for {} is already finalized. Skipping.", date);
            return;
        }

        try {
            // 2. TỔNG HỢP DỮ LIỆU TỪ CÁC BẢNG (Mock logic for now - you would query actual repositories)
            // Ví dụ: BigDecimal totalRevenue = billRepository.sumRevenueByDate(date);
            BigDecimal totalRevenue = new BigDecimal("1200000"); // Mock
            BigDecimal saasRevenue = new BigDecimal("300000");
            BigDecimal commissionRevenue = new BigDecimal("900000");
            
            report.setTotalRevenue(totalRevenue);
            report.setSaasRevenue(saasRevenue);
            report.setCommissionRevenue(commissionRevenue);
            
            // Sản phẩm
            report.setFreePackagesSold(5);
            report.setBasicPackagesSold(2);
            report.setProPackagesSold(1);
            report.setEnterprisePackagesSold(0);
            
            // Rủi ro
            report.setChurnedOwnersCount(2);
            report.setAtRiskOwnersCount(5);
            
            // 3. Cập nhật metadata
            report.setLastRunAt(LocalDateTime.now());
            // Giả sử dữ liệu chạy bù vào lúc 2h sáng hôm sau thì chốt luôn
            report.setIsFinalized(true);
            
            repository.save(report);
            log.info("Successfully generated and saved AnalyticsFinancialReport for date: {}", date);
            
        } catch (Exception e) {
            log.error("Failed to generate report for date: {}", date, e);
            throw e; // Để @Transactional rollback nếu có lỗi
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getFinancialAnalyticsResponse(int days) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1); // e.g. 7 days including today
        
        List<AnalyticsFinancialReport> reports = repository.findByReportDateBetweenOrderByReportDateAsc(startDate, endDate);
        
        // Tạo JSON structure
        Map<String, Object> response = new HashMap<>();
        
        // 1. Summary
        BigDecimal totalRevenue = BigDecimal.ZERO;
        int churned = 0;
        int totalPackages = 0;
        
        int freePack = 0, basicPack = 0, proPack = 0, entPack = 0;
        
        List<Map<String, Object>> chartPoints = new ArrayList<>();
        int x = 1;
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");
        
        for (AnalyticsFinancialReport r : reports) {
            totalRevenue = totalRevenue.add(r.getTotalRevenue());
            churned += r.getChurnedOwnersCount();
            
            freePack += r.getFreePackagesSold();
            basicPack += r.getBasicPackagesSold();
            proPack += r.getProPackagesSold();
            entPack += r.getEnterprisePackagesSold();
            
            // Chart point
            Map<String, Object> point = new HashMap<>();
            point.put("x", x);
            point.put("y", r.getTotalRevenue().doubleValue());
            point.put("tooltip", r.getReportDate().format(formatter) + " - " + formatMoney(r.getTotalRevenue().doubleValue()));
            point.put("label", r.getReportDate().format(formatter)); // Thêm key label
            chartPoints.add(point);
            
            x++;
        }
        
        totalPackages = freePack + basicPack + proPack + entPack;
        
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalRevenue", totalRevenue.doubleValue());
        summary.put("mrr", totalRevenue.multiply(new BigDecimal("4")).doubleValue()); // Ước lượng
        summary.put("churnedOwners", churned);
        response.put("summary", summary);
        
        // 2. Revenue Chart
        Map<String, Object> revenueChart = new HashMap<>();
        revenueChart.put("minY", 0);
        revenueChart.put("maxY", totalRevenue.doubleValue() > 0 ? totalRevenue.doubleValue() * 1.2 : 5000000);
        revenueChart.put("intervalY", 1000000);
        revenueChart.put("points", chartPoints);
        response.put("revenueChart", revenueChart);
        
        // 3. Package Sales Chart
        Map<String, Object> packageSalesChart = new HashMap<>();
        packageSalesChart.put("totalSold", totalPackages);
        
        List<Map<String, Object>> sections = new ArrayList<>();
        if (totalPackages > 0) {
            sections.add(createSection(freePack, totalPackages, "#E5E7EB", "Free"));
            sections.add(createSection(basicPack, totalPackages, "#3B82F6", "Basic"));
            sections.add(createSection(proPack, totalPackages, "#8B5CF6", "Pro"));
            sections.add(createSection(entPack, totalPackages, "#10B981", "Enterprise"));
        }
        packageSalesChart.put("sections", sections);
        response.put("packageSalesChart", packageSalesChart);
        
        // 4. Actionable Insights
        List<Map<String, Object>> insights = new ArrayList<>();
        if (churned > 0) {
            Map<String, Object> insight = new HashMap<>();
            insight.put("type", "CHURN_WARNING");
            insight.put("message", "Có " + churned + " Chủ nhà vừa hết hạn gói nhưng chưa gia hạn.");
            insight.put("actionText", "Gửi Voucher 20%");
            insight.put("actionApiUrl", "/v1/admin/marketing/send-voucher?type=churned");
            insights.add(insight);
        }
        response.put("actionableInsights", insights);
        
        return response;
    }
    
    private Map<String, Object> createSection(int value, int total, String color, String title) {
        Map<String, Object> sec = new HashMap<>();
        sec.put("value", value);
        sec.put("color", color);
        sec.put("title", title);
        double percentage = (double) value / total * 100;
        sec.put("percentage", Math.round(percentage * 10.0) / 10.0);
        return sec;
    }
    
    private String formatMoney(double amount) {
        if (amount >= 1000000) {
            return String.format("%.1fM", amount / 1000000);
        } else if (amount >= 1000) {
            return String.format("%.0fk", amount / 1000);
        }
        return String.valueOf((int)amount);
    }
}
