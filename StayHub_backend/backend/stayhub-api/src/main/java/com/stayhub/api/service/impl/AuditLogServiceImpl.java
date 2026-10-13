package com.stayhub.api.service.impl;

import com.stayhub.api.entity.AuditLog;
import com.stayhub.api.repository.AuditLogRepository;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogServiceImpl implements AuditLogService {

    private final AuditLogRepository auditLogRepository;

    @Override
    public void logAction(String entityType, Long entityId, String action, Long userId, String userName, String changes) {
        try {
            AuditLog logEntry = AuditLog.builder()
                    .entityType(entityType)
                    .entityId(entityId)
                    .action(action)
                    .changedBy(userId)
                    .changedByName(userName)
                    .changes(changes)
                    .createdAt(LocalDateTime.now())
                    .build();
            auditLogRepository.save(logEntry);
            log.info("AuditLog saved for {} id={}: {}", entityType, entityId, action);
        } catch (Exception e) {
            log.error("Failed to save AuditLog", e);
        }
    }

    @Override
    public List<AuditLog> getLogsForEntity(String entityType, Long entityId) {
        return auditLogRepository.findByEntityTypeAndEntityIdOrderByCreatedAtDesc(entityType, entityId);
    }
}
