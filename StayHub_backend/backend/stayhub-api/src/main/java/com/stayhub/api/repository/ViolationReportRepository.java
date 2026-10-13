package com.stayhub.api.repository;

import com.stayhub.api.entity.ViolationReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ViolationReportRepository extends JpaRepository<ViolationReport, Long> {
    List<ViolationReport> findByRoomId(Long roomId);
    List<ViolationReport> findByContractId(Long contractId);
    List<ViolationReport> findByTargetTypeAndTargetId(String targetType, Long targetId);
}