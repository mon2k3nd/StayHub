package com.stayhub.api.controller;

import com.stayhub.api.entity.AuditLog;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/audit-logs")
@RequiredArgsConstructor
public class AuditLogController {

    private final AuditLogService auditLogService;

    @GetMapping("/{entityType}/{entityId}")
    public ResponseEntity<List<AuditLog>> getLogs(
            @PathVariable String entityType,
            @PathVariable Long entityId,
            Authentication auth) {
        // Có thể check quyền xem log tại đây nếu cần
        return ResponseEntity.ok(auditLogService.getLogsForEntity(entityType, entityId));
    }
}
