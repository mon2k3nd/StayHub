package com.stayhub.api.repository;

import com.stayhub.api.entity.SaasPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SaasPlanRepository extends JpaRepository<SaasPlan, Long> {
    Optional<SaasPlan> findByPlanType(String planType);
}
