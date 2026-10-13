package com.stayhub.api.service;

import com.stayhub.api.entity.AnalyticsRiskReport;
import com.stayhub.api.repository.AnalyticsRiskReportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
public class AnalyticsRiskReportService {

    private final AnalyticsRiskReportRepository repository;

    @Transactional
    public void generateReportForDate(LocalDate date) {
        log.info("Starting ETL process for AnalyticsRiskReport for date: {}", date);

        Optional<AnalyticsRiskReport> existingOpt = repository.findByReportDate(date);
        AnalyticsRiskReport report = existingOpt.orElseGet(() ->
                AnalyticsRiskReport.builder()
                        .reportDate(date)
                        .reportMonth(date.getMonthValue())
                        .reportYear(date.getYear())
                        .build()
        );

        if (Boolean.TRUE.equals(report.getIsFinalized())) {
            log.warn("Risk Report for {} is already finalized. Skipping.", date);
            return;
        }

        try {
            // Mock ETL logic
            int unpaidBills = 45;
            BigDecimal totalDebtAmount = new BigDecimal("250000000");

            report.setTotalUnpaidBills(unpaidBills);
            report.setTotalDebtAmount(totalDebtAmount);

            // Operational Risks
            report.setReportedIncidents(12);
            report.setCancelledContracts(3);

            // eKYC Health
            report.setKycSubmitted(100);
            report.setKycApproved(80);
            report.setKycRejected(20);

            // Metadata
            report.setLastRunAt(LocalDateTime.now());
            report.setIsFinalized(true);

            repository.save(report);
            log.info("Successfully generated and saved AnalyticsRiskReport for date: {}", date);

        } catch (Exception e) {
            log.error("Failed to generate risk report for date: {}", date, e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getRiskAnalyticsResponse(int days) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        List<AnalyticsRiskReport> reports = repository.findByReportDateBetweenOrderByReportDateAsc(startDate, endDate);

        Map<String, Object> response = new HashMap<>();

        // Summary Accumulators
        BigDecimal currentTotalDebt = BigDecimal.ZERO;
        int currentUnpaidBills = 0;
        
        int totalKycSub = 0;
        int totalKycApp = 0;
        int totalKycRej = 0;

        List<Map<String, Object>> debtPoints = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");

        int x = 1;
        for (AnalyticsRiskReport r : reports) {
            currentTotalDebt = r.getTotalDebtAmount();
            currentUnpaidBills = r.getTotalUnpaidBills();

            totalKycSub += r.getKycSubmitted();
            totalKycApp += r.getKycApproved();
            totalKycRej += r.getKycRejected();

            // Trend point for Debt
            Map<String, Object> point = new HashMap<>();
            point.put("x", x);
            point.put("y", r.getTotalDebtAmount().doubleValue());
            point.put("tooltip", formatMoney(r.getTotalDebtAmount().doubleValue()));
            point.put("label", r.getReportDate().format(formatter));
            debtPoints.add(point);
            x++;
        }

        double rejectionRate = 0.0;
        if (totalKycSub > 0) {
            rejectionRate = (double) totalKycRej / totalKycSub * 100;
        }

        // 1. Summary
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalDebtAmount", currentTotalDebt.doubleValue());
        summary.put("unpaidBills", currentUnpaidBills);
        summary.put("kycRejectionRate", Math.round(rejectionRate * 10.0) / 10.0);
        response.put("summary", summary);

        // 2. Debt Trend Chart
        Map<String, Object> debtTrendChart = new HashMap<>();
        debtTrendChart.put("minY", 0);
        debtTrendChart.put("maxY", currentTotalDebt.doubleValue() > 0 ? currentTotalDebt.doubleValue() * 1.5 : 500000000);
        debtTrendChart.put("intervalY", 50000000); // 50M
        debtTrendChart.put("points", debtPoints);
        response.put("debtTrendChart", debtTrendChart);

        // 3. KYC Health Chart
        Map<String, Object> kycHealthChart = new HashMap<>();
        kycHealthChart.put("totalProcessed", totalKycSub);
        
        List<Map<String, Object>> sections = new ArrayList<>();
        if (totalKycSub > 0) {
            sections.add(createSection("Duyệt thành công", totalKycApp, totalKycSub, "#10B981"));
            sections.add(createSection("Bị từ chối", totalKycRej, totalKycSub, "#EF4444"));
        }
        kycHealthChart.put("sections", sections);
        response.put("kycHealthChart", kycHealthChart);

        // 4. Actionable Insights
        List<Map<String, Object>> insights = new ArrayList<>();
        if (currentUnpaidBills > 0) {
            Map<String, Object> insight = new HashMap<>();
            insight.put("type", "HIGH_DEBT_WARNING");
            insight.put("message", "Có " + currentUnpaidBills + " hóa đơn quá hạn với tổng nợ " + formatMoney(currentTotalDebt.doubleValue()) + ". Cần nhắc nhở!");
            insight.put("actionText", "Gửi thông báo nhắc nợ");
            insights.add(insight);
        }
        
        if (rejectionRate > 15.0) {
            Map<String, Object> insight2 = new HashMap<>();
            insight2.put("type", "KYC_WARNING");
            insight2.put("message", "Tỷ lệ từ chối eKYC đang ở mức cao (" + Math.round(rejectionRate * 10.0) / 10.0 + "%). Cần kiểm tra lại model AI.");
            insight2.put("actionText", "Xem chi tiết lỗi");
            insights.add(insight2);
        }
        
        response.put("actionableInsights", insights);

        return response;
    }

    private Map<String, Object> createSection(String title, int value, int total, String color) {
        Map<String, Object> sec = new HashMap<>();
        sec.put("title", title);
        sec.put("value", value);
        sec.put("color", color);
        double percentage = (double) value / total * 100;
        sec.put("percentage", Math.round(percentage * 10.0) / 10.0);
        return sec;
    }
    
    private String formatMoney(double amount) {
        if (amount >= 1000000000) {
            return String.format("%.1f Tỷ", amount / 1000000000);
        } else if (amount >= 1000000) {
            return String.format("%.0f Triệu", amount / 1000000);
        } else if (amount >= 1000) {
            return String.format("%.0fk", amount / 1000);
        }
        return String.valueOf((int)amount);
    }
}
