package com.stayhub.api.service;

import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class SaaSExpiryScheduler {

    private final UserRepository userRepository;

    // Kích hoạt vào 00:00 UTC+7 hàng ngày
    @Scheduled(cron = "0 0 0 * * *", zone = "Asia/Ho_Chi_Minh")
    public void scanAndDowngradeExpiredUsers() {
        log.info("[CRON JOB] Starting daily SaaS expiry check...");
        try {
            int updatedCount = userRepository.downgradeExpiredPackages();
            log.info("[CRON JOB] Downgraded {} expired owners to FREE package.", updatedCount);
        } catch (Exception e) {
            log.error("[CRON JOB] Error while running SaaS expiry job: {}", e.getMessage(), e);
        }
    }
}
