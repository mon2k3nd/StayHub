package com.stayhub.api.service;

import com.stayhub.api.entity.Vehicle;
import java.util.List;

public interface VehicleService {
    List<Vehicle> getByOwner(Long ownerId);
    List<Vehicle> getByBranch(Long branchId);
    List<Vehicle> getByRoom(Long roomId);
    List<Vehicle> getByTenant(Long tenantId);
    Vehicle create(Vehicle vehicle);
    Vehicle update(Long id, Vehicle vehicle);
    void delete(Long id);
    Vehicle updateStatus(Long id, String status);
}
