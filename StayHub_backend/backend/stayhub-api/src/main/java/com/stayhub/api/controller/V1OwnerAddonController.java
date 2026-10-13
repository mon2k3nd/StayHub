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
@RequestMapping("/v1/owner/addons")
@RequiredArgsConstructor
@CheckRole("OWNER")
public class V1OwnerAddonController {

    private final AddonServiceService addonServiceService;

    @GetMapping
    public ResponseEntity<ApiResponse<Object>> getAddons(Authentication auth) {
        Long ownerId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.getOwnerAddons(ownerId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Object>> createAddon(Authentication auth, @RequestBody Map<String, Object> body) {
        Long ownerId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.createAddon(ownerId, body)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Object>> deleteAddon(@PathVariable Long id) {
        addonServiceService.deleteAddon(id);
        return ResponseEntity.ok(ApiResponse.ok("Xóa dịch vụ thành công"));
    }

    @GetMapping("/rooms/{roomId}/requests")
    public ResponseEntity<ApiResponse<Object>> getRoomRequests(@PathVariable Long roomId, @RequestParam(defaultValue = "PENDING") String status) {
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.getRoomRequests(roomId, status)));
    }

    @PutMapping("/requests/{requestId}")
    public ResponseEntity<ApiResponse<Object>> respondToRequest(
            @PathVariable Long requestId,
            @RequestBody Map<String, Object> body) {
        boolean approved = Boolean.parseBoolean(body.get("approved").toString());
        String note = body.containsKey("note") ? body.get("note").toString() : null;
        
        return ResponseEntity.ok(ApiResponse.ok(addonServiceService.respondToRequest(requestId, approved, note)));
    }
}
