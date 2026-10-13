package com.stayhub.api.service.impl;

import com.stayhub.api.entity.Vehicle;
import com.stayhub.api.repository.VehicleRepository;
import com.stayhub.api.service.VehicleService;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VehicleServiceImpl implements VehicleService {

    private final VehicleRepository vehicleRepository;
    private final AuditLogService auditLogService;

    @Override
    public List<Vehicle> getByOwner(Long ownerId) {
        return vehicleRepository.findByOwnerIdOrderByCreatedAtDesc(ownerId);
    }

    @Override
    public List<Vehicle> getByBranch(Long branchId) {
        return vehicleRepository.findByBranchId(branchId);
    }

    @Override
    public List<Vehicle> getByRoom(Long roomId) {
        return vehicleRepository.findByRoomId(roomId);
    }

    @Override
    public List<Vehicle> getByTenant(Long tenantId) {
        return vehicleRepository.findByTenantId(tenantId);
    }

    @Override
    public Vehicle create(Vehicle vehicle) {
        Vehicle saved = vehicleRepository.save(vehicle);
        auditLogService.logAction(
                "VEHICLE", saved.getId(), "CREATE",
                null, "System",
                String.format("Thêm xe %s (%s) biển số %s", saved.getVehicleType(), saved.getBrand(), saved.getLicensePlate())
        );
        return saved;
    }

    @Override
    public Vehicle update(Long id, Vehicle vehicle) {
        Vehicle existing = vehicleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Xe không tồn tại!"));
        
        String oldChanges = String.format("Cũ: %s (%s) biển %s", existing.getVehicleType(), existing.getBrand(), existing.getLicensePlate());
        
        existing.setVehicleType(vehicle.getVehicleType());
        existing.setLicensePlate(vehicle.getLicensePlate());
        existing.setBrand(vehicle.getBrand());
        existing.setColor(vehicle.getColor());
        existing.setMonthlyFee(vehicle.getMonthlyFee());
        
        Vehicle saved = vehicleRepository.save(existing);
        
        auditLogService.logAction(
                "VEHICLE", id, "UPDATE",
                null, "System",
                oldChanges + " -> Mới: " + saved.getVehicleType() + " (" + saved.getBrand() + ") biển " + saved.getLicensePlate()
        );
        return saved;
    }

    @Override
    public void delete(Long id) {
        Vehicle existing = vehicleRepository.findById(id).orElse(null);
        if (existing != null) {
            auditLogService.logAction(
                    "VEHICLE", id, "DELETE",
                    null, "System",
                    String.format("Xóa xe %s biển số %s của khách ID %d", existing.getVehicleType(), existing.getLicensePlate(), existing.getTenantId())
            );
            vehicleRepository.deleteById(id);
        }
    }

    @Override
    public Vehicle updateStatus(Long id, String status) {
        Vehicle existing = vehicleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Xe không tồn tại!"));
        String oldStatus = existing.getStatus();
        existing.setStatus(status);
        
        Vehicle saved = vehicleRepository.save(existing);
        
        auditLogService.logAction(
                "VEHICLE", id, "UPDATE_STATUS",
                null, "System",
                "Trạng thái: " + oldStatus + " -> " + status
        );
        return saved;
    }
}
