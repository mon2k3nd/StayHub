package com.stayhub.api.controller;

import com.stayhub.api.service.SaasService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/saas-stub")
@RequiredArgsConstructor
public class AdminSaasController {

    private final SaasService saasService;

    @GetMapping("/plans")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getSaasPlans() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", saasService.getAdminSaasStats().get("plans"));
        return ResponseEntity.ok(response);
    }
    
    @org.springframework.web.bind.annotation.PutMapping("/plans/{planType}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> updateSaasPlan(
            @org.springframework.web.bind.annotation.PathVariable String planType,
            @org.springframework.web.bind.annotation.RequestBody Map<String, Object> payload) {
        
        saasService.updatePlan(planType, payload);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Đã cập nhật giới hạn gói cước " + planType);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/campaigns")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getSaasCampaigns() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", new java.util.ArrayList<>()); // Stub for now
        return ResponseEntity.ok(response);
    }
}
