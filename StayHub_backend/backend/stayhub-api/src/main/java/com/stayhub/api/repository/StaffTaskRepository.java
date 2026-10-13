package com.stayhub.api.repository;

import com.stayhub.api.entity.StaffTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StaffTaskRepository extends JpaRepository<StaffTask, Long> {
    List<StaffTask> findByBranchIdOrderByCreatedAtDesc(Long branchId);
    List<StaffTask> findByAssignedStaffIdOrderByCreatedAtDesc(Long staffId);
    List<StaffTask> findByBranchIdAndStatusOrderByCreatedAtDesc(Long branchId, String status);
}
