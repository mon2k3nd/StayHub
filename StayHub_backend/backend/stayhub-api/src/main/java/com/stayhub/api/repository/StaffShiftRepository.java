package com.stayhub.api.repository;

import com.stayhub.api.entity.StaffShift;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StaffShiftRepository extends JpaRepository<StaffShift, Long> {
    List<StaffShift> findByBranchIdOrderByStartTimeDesc(Long branchId);
    List<StaffShift> findByStaffIdOrderByStartTimeDesc(Long staffId);
}
