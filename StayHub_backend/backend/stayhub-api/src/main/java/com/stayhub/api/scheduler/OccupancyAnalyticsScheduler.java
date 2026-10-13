package com.stayhub.api.scheduler;

import com.stayhub.api.service.AnalyticsOccupancyReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Slf4j
@Component
@RequiredArgsConstructor
public class OccupancyAnalyticsScheduler {

    private final AnalyticsOccupancyReportService occupancyReportService;

    // Run at 00:10:00 every day
    @Scheduled(cron = "0 10 0 * * ?")
    public void runDailyOccupancyAnalytics() {
        LocalDate targetDate = LocalDate.now().minusDays(1);
        log.info("Starting Daily Occupancy Analytics Job for date: {}", targetDate);
        
        try {
            occupancyReportService.generateReportForDate(targetDate);
            log.info("Successfully completed Daily Occupancy Analytics Job for date: {}", targetDate);
        } catch (Exception e) {
            log.error("Failed to execute Daily Occupancy Analytics Job for date: {}", targetDate, e);
        }
    }
}
