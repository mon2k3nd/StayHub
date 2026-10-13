package com.stayhub.api.repository;

import com.stayhub.api.entity.ServicePool;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServicePoolRepository extends JpaRepository<ServicePool, Long> {
    List<ServicePool> findByBranchId(Long branchId);
}
