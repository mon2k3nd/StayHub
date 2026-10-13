package com.stayhub.api.controller;

import com.stayhub.api.entity.ViolationReport;
import com.stayhub.api.service.ViolationReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/violation-reports")
@RequiredArgsConstructor
public class ViolationReportController {

    private final ViolationReportService violationReportService;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<ViolationReport>> getViolationsByRoom(
            @PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(violationReportService.getViolationsByRoom(roomId));
    }

    @GetMapping("/target/{targetType}/{targetId}")
    public ResponseEntity<List<ViolationReport>> getViolationsByTarget(
            @PathVariable String targetType, @PathVariable Long targetId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(violationReportService.getViolationsByTarget(targetType, targetId));
    }

    @PostMapping
    public ResponseEntity<ViolationReport> createViolation(
            @RequestBody ViolationReport violation,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        Long userId = (Long) auth.getPrincipal();
        // Khóa reporterId từ token, không để client tự điền
        violation.setReporterId(userId);
        return ResponseEntity.ok(violationReportService.createViolation(violation));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ViolationReport> updateViolationStatus(
            @PathVariable Long id, @RequestParam String status,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!isOwner && !isStaff) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(violationReportService.updateViolationStatus(id, status));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteViolation(
            @PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isOwner) return ResponseEntity.status(403).build();
        violationReportService.deleteViolation(id);
        return ResponseEntity.ok().build();
    }
}
