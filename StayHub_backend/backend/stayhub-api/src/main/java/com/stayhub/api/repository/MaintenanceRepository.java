package com.stayhub.api.repository;

import com.stayhub.api.entity.Maintenance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MaintenanceRepository extends JpaRepository<Maintenance, Long> {
    List<Maintenance> findByRoomId(Long roomId);
    List<Maintenance> findByTenantId(Long tenantId);
    List<Maintenance> findByAssignedStaffId(Long staffId);

    @Query("SELECT m FROM Maintenance m JOIN Room r ON m.roomId = r.id " +
           "WHERE m.assignedStaffId = :staffId " +
           "OR (r.branchId IN :branchIds AND m.status = 'NEW') " +
           "ORDER BY m.createdAt DESC")
    List<Maintenance> findForStaff(@Param("staffId") Long staffId, @Param("branchIds") List<Long> branchIds);
    @Query("SELECT m FROM Maintenance m WHERE m.roomId = :roomId AND m.status IN ('NEW', 'ASSIGNED', 'PROCESSING')")
    List<Maintenance> findPendingByRoomId(@Param("roomId") Long roomId);

    @Query("SELECT m FROM Maintenance m JOIN Room r ON m.roomId = r.id WHERE r.ownerId = :ownerId ORDER BY m.createdAt DESC")
    List<Maintenance> findByOwnerId(@Param("ownerId") Long ownerId);
}
