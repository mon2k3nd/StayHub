package com.stayhub.api.service;

import com.stayhub.api.entity.BranchRule;
import java.util.List;

public interface BranchRuleService {
    List<BranchRule> getRulesByBranch(Long branchId);
    BranchRule createRule(BranchRule rule);
    BranchRule updateRule(Long id, BranchRule rule);
    void deleteRule(Long id);
}
