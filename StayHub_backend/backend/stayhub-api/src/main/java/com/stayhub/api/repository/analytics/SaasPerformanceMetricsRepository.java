package com.stayhub.api.repository.analytics;

import com.stayhub.api.entity.analytics.SaasPerformanceMetrics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SaasPerformanceMetricsRepository extends JpaRepository<SaasPerformanceMetrics, Long> {
    Optional<SaasPerformanceMetrics> findFirstByOrderByRecordedAtDesc();
}
