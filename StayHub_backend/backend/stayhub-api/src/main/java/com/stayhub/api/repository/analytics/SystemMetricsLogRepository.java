package com.stayhub.api.repository.analytics;

import com.stayhub.api.entity.analytics.SystemMetricsLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SystemMetricsLogRepository extends JpaRepository<SystemMetricsLog, Long> {
    Optional<SystemMetricsLog> findFirstByOrderByRecordedAtDesc();
}
