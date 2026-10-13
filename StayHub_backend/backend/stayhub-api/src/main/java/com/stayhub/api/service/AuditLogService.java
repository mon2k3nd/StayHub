package com.stayhub.api.service;

import com.stayhub.api.entity.AuditLog;
import java.util.List;

public interface AuditLogService {
    void logAction(String entityType, Long entityId, String action, Long userId, String userName, String changes);
    List<AuditLog> getLogsForEntity(String entityType, Long entityId);
}
