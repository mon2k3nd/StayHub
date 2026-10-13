package com.stayhub.api.service;

import com.stayhub.api.entity.AnalyticsOccupancyReport;
import com.stayhub.api.repository.AnalyticsOccupancyReportRepository;
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
public class AnalyticsOccupancyReportService {

    private final AnalyticsOccupancyReportRepository repository;

    @Transactional
    public void generateReportForDate(LocalDate date) {
        log.info("Starting ETL process for AnalyticsOccupancyReport for date: {}", date);

        Optional<AnalyticsOccupancyReport> existingOpt = repository.findByReportDate(date);
        AnalyticsOccupancyReport report = existingOpt.orElseGet(() ->
                AnalyticsOccupancyReport.builder()
                        .reportDate(date)
                        .reportMonth(date.getMonthValue())
                        .reportYear(date.getYear())
                        .build()
        );

        if (Boolean.TRUE.equals(report.getIsFinalized())) {
            log.warn("Occupancy Report for {} is already finalized. Skipping.", date);
            return;
        }

        try {
            // Mock ETL from rooms, branches, tenant_profiles
            int totalRooms = 1500;
            int occupiedRooms = 1200;
            int maintenanceRooms = 50;
            int availableRooms = totalRooms - occupiedRooms - maintenanceRooms;
            
            BigDecimal occupancyRate = BigDecimal.ZERO;
            if (totalRooms > 0) {
                occupancyRate = BigDecimal.valueOf((double) occupiedRooms / totalRooms * 100)
                        .setScale(2, RoundingMode.HALF_UP);
            }

            report.setTotalProperties(45);
            report.setTotalRooms(totalRooms);
            report.setOccupiedRooms(occupiedRooms);
            report.setAvailableRooms(availableRooms);
            report.setMaintenanceRooms(maintenanceRooms);
            report.setOccupancyRate(occupancyRate);

            // Demographics: Occupation
            report.setStudentTenants(600);
            report.setWorkerTenants(400);
            report.setOtherOccupationTenants(200);

            // Demographics: Age
            report.setGenZTenants(700);
            report.setMillennialTenants(400);
            report.setOtherAgeTenants(100);

            // Metadata
            report.setLastRunAt(LocalDateTime.now());
            report.setIsFinalized(true);

            repository.save(report);
            log.info("Successfully generated and saved AnalyticsOccupancyReport for date: {}", date);

        } catch (Exception e) {
            log.error("Failed to generate occupancy report for date: {}", date, e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getOccupancyAnalyticsResponse(int days) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        List<AnalyticsOccupancyReport> reports = repository.findByReportDateBetweenOrderByReportDateAsc(startDate, endDate);

        Map<String, Object> response = new HashMap<>();

        // Summary & Accumulators
        int currentTotalRooms = 0;
        int currentAvailableRooms = 0;
        BigDecimal currentOccupancyRate = BigDecimal.ZERO;
        
        int totalStudents = 0, totalWorkers = 0, totalOtherOcc = 0;
        int totalGenZ = 0, totalMillennial = 0, totalOtherAge = 0;
        int maintenanceWarningCount = 0;

        List<Map<String, Object>> trendPoints = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");

        for (AnalyticsOccupancyReport r : reports) {
            // Update latest stats
            currentTotalRooms = r.getTotalRooms();
            currentAvailableRooms = r.getAvailableRooms();
            currentOccupancyRate = r.getOccupancyRate();

            // Accumulate demographics
            totalStudents += r.getStudentTenants();
            totalWorkers += r.getWorkerTenants();
            totalOtherOcc += r.getOtherOccupationTenants();

            totalGenZ += r.getGenZTenants();
            totalMillennial += r.getMillennialTenants();
            totalOtherAge += r.getOtherAgeTenants();

            if (r.getMaintenanceRooms() > 10) {
                maintenanceWarningCount = r.getMaintenanceRooms();
            }

            // Trend point
            Map<String, Object> point = new HashMap<>();
            point.put("label", r.getReportDate().format(formatter));
            point.put("y", r.getOccupancyRate().doubleValue());
            point.put("tooltip", r.getOccupancyRate() + "%");
            trendPoints.add(point);
        }

        // 1. Summary
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalRooms", currentTotalRooms);
        summary.put("occupancyRate", currentOccupancyRate.doubleValue());
        summary.put("availableRooms", currentAvailableRooms);
        response.put("summary", summary);

        // 2. Trend Chart
        Map<String, Object> occupancyTrendChart = new HashMap<>();
        occupancyTrendChart.put("points", trendPoints);
        response.put("occupancyTrendChart", occupancyTrendChart);

        // 3. Demographics
        Map<String, Object> demographicsChart = new HashMap<>();
        
        int totalOcc = totalStudents + totalWorkers + totalOtherOcc;
        List<Map<String, Object>> occupation = new ArrayList<>();
        if (totalOcc > 0) {
            occupation.add(createSection("Sinh viên", totalStudents, totalOcc, "#3B82F6"));
            occupation.add(createSection("Người đi làm", totalWorkers, totalOcc, "#10B981"));
            occupation.add(createSection("Khác", totalOtherOcc, totalOcc, "#9CA3AF"));
        }
        demographicsChart.put("occupation", occupation);

        int totalAge = totalGenZ + totalMillennial + totalOtherAge;
        List<Map<String, Object>> ageGroup = new ArrayList<>();
        if (totalAge > 0) {
            ageGroup.add(createSection("Gen Z", totalGenZ, totalAge, "#8B5CF6"));
            ageGroup.add(createSection("Millennials", totalMillennial, totalAge, "#F59E0B"));
            ageGroup.add(createSection("Khác", totalOtherAge, totalAge, "#EC4899"));
        }
        demographicsChart.put("ageGroup", ageGroup);
        
        response.put("demographicsChart", demographicsChart);

        // 4. Actionable Insights
        List<Map<String, Object>> insights = new ArrayList<>();
        if (maintenanceWarningCount > 0) {
            Map<String, Object> insight = new HashMap<>();
            insight.put("type", "MAINTENANCE_WARNING");
            insight.put("message", "Có " + maintenanceWarningCount + " phòng đang bảo trì hệ thống. Cần đốc thúc!");
            insight.put("actionText", "Xem danh sách");
            insights.add(insight);
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
}
