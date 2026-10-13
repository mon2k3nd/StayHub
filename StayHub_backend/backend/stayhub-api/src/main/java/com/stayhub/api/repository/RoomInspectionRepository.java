package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomInspection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomInspectionRepository extends JpaRepository<RoomInspection, Long> {
    List<RoomInspection> findByRoomId(Long roomId);
    List<RoomInspection> findByTenantId(Long tenantId);
    List<RoomInspection> findByStaffId(Long staffId);
}
