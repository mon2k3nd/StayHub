package com.stayhub.api.repository;

import com.stayhub.api.entity.BranchGroupMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BranchGroupMessageRepository extends JpaRepository<BranchGroupMessage, Long> {
    List<BranchGroupMessage> findByBranchIdOrderByCreatedAtAsc(Long branchId);
}
