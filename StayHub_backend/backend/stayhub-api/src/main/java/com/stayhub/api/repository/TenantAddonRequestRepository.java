package com.stayhub.api.repository;

import com.stayhub.api.entity.TenantAddonRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TenantAddonRequestRepository extends JpaRepository<TenantAddonRequest, Long> {
    List<TenantAddonRequest> findByTenantId(Long tenantId);
    List<TenantAddonRequest> findByRoomIdAndStatus(Long roomId, String status);
    List<TenantAddonRequest> findByRoomIdAndIsBilledFalseAndStatus(Long roomId, String status);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("UPDATE TenantAddonRequest req SET req.isBilled = true WHERE req.id IN :ids")
    void markAsBilled(@org.springframework.data.repository.query.Param("ids") List<Long> ids);
}
