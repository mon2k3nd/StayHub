package com.stayhub.api.service;

import com.stayhub.api.entity.analytics.MarketIntelligence;
import com.stayhub.api.entity.analytics.OwnerFinancialSnapshot;
import com.stayhub.api.entity.analytics.SaasPerformanceMetrics;
import com.stayhub.api.entity.analytics.SystemMetricsLog;
import com.stayhub.api.repository.analytics.MarketIntelligenceRepository;
import com.stayhub.api.repository.analytics.OwnerFinancialSnapshotRepository;
import com.stayhub.api.repository.analytics.SaasPerformanceMetricsRepository;
import com.stayhub.api.repository.analytics.SystemMetricsLogRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsDataSeederService {

    private final MarketIntelligenceRepository marketRepo;
    private final OwnerFinancialSnapshotRepository ownerFinRepo;
    private final SaasPerformanceMetricsRepository saasRepo;
    private final SystemMetricsLogRepository sysRepo;

    @PostConstruct
    @Transactional
    public void seedAnalyticsData() {
        if (sysRepo.count() == 0) {
            log.info("Seeding SystemMetricsLog data...");
            sysRepo.save(SystemMetricsLog.builder()
                    .recordedAt(LocalDateTime.now())
                    .cpuUsage(34.5)
                    .ramUsage(62.0)
                    .avgApiLatencyMs(45.2)
                    .totalDbQueries(1240L)
                    .storageUsedGb(1200.5)
                    .bandwidthUsedGb(450.0)
                    .errorRate(0.01)
                    .activeConnections(5420)
                    .build());
        }

        if (marketRepo.count() == 0) {
            log.info("Seeding MarketIntelligence data...");
            marketRepo.save(MarketIntelligence.builder()
                    .recordedAt(LocalDateTime.now())
                    .avgRentPrice(4500000.0)
                    .regionOccupancyRate(85.4)
                    .topSearchedRegion("Cầu Giấy")
                    .totalAvailableRooms(1245)
                    .avgDaysToFindTenant(5.2)
                    .avgRoomSizeSqm(22.0)
                    .pricePerSqm(205000.0)
                    .build());
        }

        if (saasRepo.count() == 0) {
            log.info("Seeding SaasPerformanceMetrics data...");
            saasRepo.save(SaasPerformanceMetrics.builder()
                    .recordedAt(LocalDateTime.now())
                    .arr(12500000000.0)
                    .mrr(1040000000.0)
                    .ltv(4500000.0)
                    .cac(250000.0)
                    .churnRate(1.2)
                    .premiumAccounts(4200)
                    .basicAccounts(12500)
                    .dau(8540)
                    .mau(45200)
                    .build());
        }
    }
}
