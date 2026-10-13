package com.stayhub.api.controller;

import com.stayhub.api.entity.NotificationScope;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/admin/notifications")
@RequiredArgsConstructor
public class AdminNotificationController {

    private final NotificationService notificationService;

    @PostMapping("/broadcast")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> broadcastGlobal(@RequestBody Map<String, Object> body) {
        // adminId could be extracted from Principal, assuming 1L for now or from body
        Long adminId = 1L; // Mock admin id
        NotificationScope scope = NotificationScope.valueOf(body.get("scope").toString());
        String title = body.get("title").toString();
        String content = body.get("content").toString();

        notificationService.broadcastGlobal(adminId, scope, title, content);
        return ResponseEntity.ok(Map.of("message", "Broadcast initiated."));
    }
}
