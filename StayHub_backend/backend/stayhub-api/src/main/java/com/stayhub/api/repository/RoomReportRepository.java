package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoomReportRepository extends JpaRepository<RoomReport, Long> {
}
