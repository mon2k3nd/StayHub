package com.stayhub.api.repository;

import com.stayhub.api.entity.SystemFeatureFlag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FeatureFlagRepository extends JpaRepository<SystemFeatureFlag, String> {
}
