package com.stayhub.api.repository;

import com.stayhub.api.entity.UtilityConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UtilityConfigRepository extends JpaRepository<UtilityConfig, Long> {
    Optional<UtilityConfig> findByBranchId(Long branchId);
}