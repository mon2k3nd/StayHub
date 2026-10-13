package com.stayhub.api.repository;

import com.stayhub.api.entity.ViewingSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ViewingScheduleRepository extends JpaRepository<ViewingSchedule, Long> {
    List<ViewingSchedule> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);
    List<ViewingSchedule> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
    List<ViewingSchedule> findByRoomIdOrderByCreatedAtDesc(Long roomId);
}
