package com.stayhub.api.service.impl;

import com.stayhub.api.entity.BranchRule;
import com.stayhub.api.repository.BranchRuleRepository;
import com.stayhub.api.service.BranchRuleService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BranchRuleServiceImpl implements BranchRuleService {

    private final BranchRuleRepository branchRuleRepository;

    @Override
    public List<BranchRule> getRulesByBranch(Long branchId) {
        return branchRuleRepository.findByBranchId(branchId);
    }

    @Override
    @Transactional
    public BranchRule createRule(BranchRule rule) {
        return branchRuleRepository.save(rule);
    }

    @Override
    @Transactional
    public BranchRule updateRule(Long id, BranchRule rule) {
        BranchRule existing = branchRuleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rule not found"));
        existing.setTitle(rule.getTitle());
        existing.setDescription(rule.getDescription());
        existing.setPenaltyAmount(rule.getPenaltyAmount());
        existing.setAppliesTo(rule.getAppliesTo());
        existing.setIsActive(rule.getIsActive());
        return branchRuleRepository.save(existing);
    }

    @Override
    @Transactional
    public void deleteRule(Long id) {
        BranchRule existing = branchRuleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rule not found"));
        existing.setIsActive(false);
        branchRuleRepository.save(existing);
    }
}
