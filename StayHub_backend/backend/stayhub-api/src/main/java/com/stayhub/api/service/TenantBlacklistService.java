package com.stayhub.api.service;

import com.stayhub.api.entity.TenantBlacklist;
import java.util.List;

public interface TenantBlacklistService {
    TenantBlacklist reportBlacklist(Long tenantId, Long ownerId, String reason, String proofUrl);
    List<TenantBlacklist> getBlacklistsByTenant(Long tenantId);
}
