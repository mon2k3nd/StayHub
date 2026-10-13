package com.stayhub.api.scheduler;

import com.stayhub.api.service.AnalyticsFinancialReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Slf4j
@Component
@RequiredArgsConstructor
public class FinancialAnalyticsScheduler {

    private final AnalyticsFinancialReportService analyticsFinancialReportService;

    // Run at 00:05:00 every day
    @Scheduled(cron = "0 5 0 * * ?")
    public void runDailyFinancialAnalytics() {
        // Calculate for yesterday
        LocalDate targetDate = LocalDate.now().minusDays(1);
        log.info("Starting Daily Financial Analytics Job for date: {}", targetDate);
        
        try {
            analyticsFinancialReportService.generateReportForDate(targetDate);
            log.info("Successfully completed Daily Financial Analytics Job for date: {}", targetDate);
        } catch (Exception e) {
            log.error("Failed to execute Daily Financial Analytics Job for date: {}. Manual intervention may be required.", targetDate, e);
        }
    }
}
