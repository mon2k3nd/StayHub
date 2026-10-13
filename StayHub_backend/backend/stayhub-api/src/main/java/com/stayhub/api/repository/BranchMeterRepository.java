package com.stayhub.api.repository;

import com.stayhub.api.entity.BranchMeter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BranchMeterRepository extends JpaRepository<BranchMeter, Long> {
    Optional<BranchMeter> findByBranchIdAndMonthAndYear(Long branchId, int month, int year);
}
