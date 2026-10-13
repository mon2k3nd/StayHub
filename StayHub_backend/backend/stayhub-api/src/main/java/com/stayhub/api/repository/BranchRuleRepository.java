package com.stayhub.api.repository;

import com.stayhub.api.entity.BranchRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BranchRuleRepository extends JpaRepository<BranchRule, Long> {
    List<BranchRule> findByBranchId(Long branchId);
}
