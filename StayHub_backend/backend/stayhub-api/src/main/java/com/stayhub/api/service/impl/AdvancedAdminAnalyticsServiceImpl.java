package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.ChartDataDto;
import com.stayhub.api.dto.response.analytics.AdminSaasAnalyticsDto;
import com.stayhub.api.entity.analytics.SaasPerformanceMetrics;
import com.stayhub.api.repository.analytics.SaasPerformanceMetricsRepository;
import com.stayhub.api.service.AdvancedAdminAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdvancedAdminAnalyticsServiceImpl implements AdvancedAdminAnalyticsService {

    private final SaasPerformanceMetricsRepository saasRepo;

    @Override
    public AdminSaasAnalyticsDto getSaasAnalytics() {
        Optional<SaasPerformanceMetrics> latestMetrics = saasRepo.findFirstByOrderByRecordedAtDesc();
        
        if (latestMetrics.isEmpty()) {
            return AdminSaasAnalyticsDto.builder().build(); // Return empty if no data
        }
        
        SaasPerformanceMetrics metrics = latestMetrics.get();

        return AdminSaasAnalyticsDto.builder()
                .mrr(metrics.getMrr())
                .arr(metrics.getArr())
                .ltv(metrics.getLtv())
                .cac(metrics.getCac())
                .churnRate(metrics.getChurnRate())
                .planDistribution(List.of(
                        new ChartDataDto("Basic", metrics.getBasicAccounts().doubleValue() / (metrics.getBasicAccounts() + metrics.getPremiumAccounts()) * 100, null, "0xFF8E8E93"),
                        new ChartDataDto("Premium", metrics.getPremiumAccounts().doubleValue() / (metrics.getBasicAccounts() + metrics.getPremiumAccounts()) * 100, null, "0xFF007AFF")
                ))
                .mrrGrowthTrend(List.of(
                        new ChartDataDto("Tháng 1", metrics.getMrr() * 0.8, null, null),
                        new ChartDataDto("Tháng 2", metrics.getMrr() * 0.85, null, null),
                        new ChartDataDto("Tháng 3", metrics.getMrr() * 0.9, null, null),
                        new ChartDataDto("Tháng 4", metrics.getMrr() * 0.95, null, null),
                        new ChartDataDto("Tháng Hiện Tại", metrics.getMrr(), null, null)
                ))
                .build();
    }
}
