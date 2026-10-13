package com.stayhub.api.repository;

import com.stayhub.api.entity.StaffAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface StaffAssignmentRepository extends JpaRepository<StaffAssignment, Long> {
    List<StaffAssignment> findByOwnerIdAndIsActiveTrue(Long ownerId);
    List<StaffAssignment> findByStaffIdAndIsActiveTrue(Long staffId);
    List<StaffAssignment> findByBranchIdAndIsActiveTrue(Long branchId);
}
