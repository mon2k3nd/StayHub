package com.stayhub.api.controller;

import com.stayhub.api.service.SaasService;
import com.stayhub.api.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/owner/saas")
@RequiredArgsConstructor
public class OwnerSaasController {

    private final SaasService saasService;
    private final AdminService adminService; // Added to get saas plans easily, or inject SaasPlanRepository directly

    @GetMapping("/plans")
    @PreAuthorize("hasRole('OWNER')")
    public ResponseEntity<Map<String, Object>> getSaasPlans() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", adminService.getAllSaasPlans());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/buy")
    @PreAuthorize("hasRole('OWNER')")
    public ResponseEntity<Map<String, Object>> buyPlan(
            @RequestAttribute("userId") Long ownerId,
            @RequestBody Map<String, String> request) {
            
        String planType = request.get("planType");
        saasService.buyPlan(ownerId, planType);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Đăng ký gói thành công");
        return ResponseEntity.ok(response);
    }
}
