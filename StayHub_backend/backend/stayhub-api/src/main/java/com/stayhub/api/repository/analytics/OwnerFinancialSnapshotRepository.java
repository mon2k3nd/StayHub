package com.stayhub.api.repository.analytics;

import com.stayhub.api.entity.analytics.OwnerFinancialSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OwnerFinancialSnapshotRepository extends JpaRepository<OwnerFinancialSnapshot, Long> {
    Optional<OwnerFinancialSnapshot> findFirstByOwnerUsernameOrderBySnapshotDateDesc(String ownerUsername);
}
