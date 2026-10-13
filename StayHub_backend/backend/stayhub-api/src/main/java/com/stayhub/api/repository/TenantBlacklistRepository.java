package com.stayhub.api.repository;

import com.stayhub.api.entity.TenantBlacklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TenantBlacklistRepository extends JpaRepository<TenantBlacklist, Long> {
    List<TenantBlacklist> findByTenantId(Long tenantId);
    long countByTenantId(Long tenantId);
}
