package com.stayhub.api.scheduler;

import com.stayhub.api.service.AnalyticsRiskReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Slf4j
@Component
@RequiredArgsConstructor
public class RiskAnalyticsScheduler {

    private final AnalyticsRiskReportService riskReportService;

    // Run at 00:15:00 every day
    @Scheduled(cron = "0 15 0 * * ?")
    public void runDailyRiskAnalytics() {
        LocalDate targetDate = LocalDate.now().minusDays(1);
        log.info("Starting Daily Risk Analytics Job for date: {}", targetDate);
        
        try {
            riskReportService.generateReportForDate(targetDate);
            log.info("Successfully completed Daily Risk Analytics Job for date: {}", targetDate);
        } catch (Exception e) {
            log.error("Failed to execute Daily Risk Analytics Job for date: {}", targetDate, e);
        }
    }
}
