package com.stayhub.api.repository;

import com.stayhub.api.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    List<Vehicle> findByTenantId(Long tenantId);
    List<Vehicle> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);
    List<Vehicle> findByBranchId(Long branchId);
    List<Vehicle> findByRoomId(Long roomId);
    List<Vehicle> findByOwnerIdAndBranchId(Long ownerId, Long branchId);
    void deleteByTenantId(Long tenantId);
}
