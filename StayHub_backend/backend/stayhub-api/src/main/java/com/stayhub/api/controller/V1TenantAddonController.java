package com.stayhub.api.controller;

import com.stayhub.api.config.CheckRole;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.AddonServiceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/tenant/addons")
@RequiredArgsConstructor
@CheckRole({"TENANT", "ACTIVE_TENANT"})
public class V1TenantAddonController {

    private final AddonServiceService addonServiceService;

    @GetMapping("/requests")
    public ResponseEntity<ApiResponse<Object>> getMyRequests(Authentication auth) {
        Long tenantId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.getTenantRequests(tenantId)));
    }

    @GetMapping("/rooms/{roomId}/available")
    public ResponseEntity<ApiResponse<Object>> getAvailableAddons(@PathVariable Long roomId) {
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.getAvailableAddonsForRoom(roomId)));
    }

    @PostMapping("/rooms/{roomId}/order")
    public ResponseEntity<ApiResponse<Object>> orderAddon(
            Authentication auth,
            @PathVariable Long roomId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.orderAddon(tenantId, roomId, body)));
    }
}
