package com.stayhub.api.repository;

import com.stayhub.api.entity.OwnerTenantMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OwnerTenantMappingRepository extends JpaRepository<OwnerTenantMapping, Long> {
    List<OwnerTenantMapping> findByOwnerId(Long ownerId);
    List<OwnerTenantMapping> findByOwnerIdAndMappingType(Long ownerId, String mappingType);
    boolean existsByOwnerIdAndTenantId(Long ownerId, Long tenantId);
    List<OwnerTenantMapping> findByTenantIdAndMappingType(Long tenantId, String mappingType);
    List<OwnerTenantMapping> findByTenantId(Long tenantId);
}
