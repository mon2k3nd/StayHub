package com.stayhub.api.repository;

import com.stayhub.api.entity.Complaint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComplaintRepository extends JpaRepository<Complaint, Long> {
    List<Complaint> findByBranchIdOrderByCreatedAtDesc(Long branchId);
    List<Complaint> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
    List<Complaint> findByBranchIdAndStatusOrderByCreatedAtDesc(Long branchId, String status);
}
