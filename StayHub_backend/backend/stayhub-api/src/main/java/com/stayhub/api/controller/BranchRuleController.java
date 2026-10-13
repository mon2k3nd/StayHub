package com.stayhub.api.controller;

import com.stayhub.api.entity.BranchRule;
import com.stayhub.api.service.BranchRuleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/branch-rules")
@RequiredArgsConstructor
public class BranchRuleController {

    private final BranchRuleService branchRuleService;

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<List<BranchRule>> getRulesByBranch(@PathVariable Long branchId) {
        return ResponseEntity.ok(branchRuleService.getRulesByBranch(branchId));
    }

    @PostMapping
    public ResponseEntity<BranchRule> createRule(@RequestBody BranchRule rule, org.springframework.security.core.Authentication auth) {
        verifyBranchAccess(rule.getBranchId(), auth);
        return ResponseEntity.ok(branchRuleService.createRule(rule));
    }

    @PutMapping("/{id}")
    public ResponseEntity<BranchRule> updateRule(@PathVariable Long id, @RequestBody BranchRule rule, org.springframework.security.core.Authentication auth) {
        BranchRule existingRule = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRuleRepository.class).findById(id).orElseThrow(() -> new RuntimeException("Rule not found"));
        verifyBranchAccess(existingRule.getBranchId(), auth);
        return ResponseEntity.ok(branchRuleService.updateRule(id, rule));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRule(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        BranchRule existingRule = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRuleRepository.class).findById(id).orElseThrow(() -> new RuntimeException("Rule not found"));
        verifyBranchAccess(existingRule.getBranchId(), auth);
        branchRuleService.deleteRule(id);
        return ResponseEntity.ok().build();
    }
    
    private void verifyBranchAccess(Long branchId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(branchId).orElse(null);
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branchId))) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                }
            } else {
                if (!branch.getOwnerId().equals(userId)) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền thay đổi nội quy của chi nhánh này");
                }
            }
        }
    }
}
