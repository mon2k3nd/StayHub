package com.stayhub.api.repository;

import com.stayhub.api.entity.InspectionLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InspectionLogRepository extends JpaRepository<InspectionLog, Long> {
    List<InspectionLog> findByRoomId(Long roomId);
    List<InspectionLog> findByTenantId(Long tenantId);
}
