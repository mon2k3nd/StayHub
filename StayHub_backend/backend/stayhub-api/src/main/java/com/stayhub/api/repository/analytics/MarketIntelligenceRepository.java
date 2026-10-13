package com.stayhub.api.repository.analytics;

import com.stayhub.api.entity.analytics.MarketIntelligence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MarketIntelligenceRepository extends JpaRepository<MarketIntelligence, Long> {
    Optional<MarketIntelligence> findFirstByOrderByRecordedAtDesc();
}
