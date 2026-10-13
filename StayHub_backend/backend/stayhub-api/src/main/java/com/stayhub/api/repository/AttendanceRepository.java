package com.stayhub.api.repository;

import com.stayhub.api.entity.AttendanceLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRepository extends JpaRepository<AttendanceLog, Long> {
    
    // Find active check-in (no check-out yet) for a specific staff
    Optional<AttendanceLog> findByStaffIdAndCheckOutTimeIsNull(Long staffId);

    // Get all logs for a staff
    List<AttendanceLog> findByStaffIdOrderByCheckInTimeDesc(Long staffId);
}
