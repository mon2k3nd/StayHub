package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.FeatureFlagService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/v1/system")
@RequiredArgsConstructor
public class V1SystemController {
    private final FeatureFlagService featureFlagService;

    @GetMapping("/features")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> getFeatureFlags() {
        return ResponseEntity.ok(ApiResponse.<Map<String, Boolean>>builder()
                .success(true)
                .message("Success")
                .data(featureFlagService.getAllFeatureFlags())
                .build());
    }
    @org.springframework.web.bind.annotation.PutMapping("/features/{key}")
    public ResponseEntity<ApiResponse<Boolean>> updateFeatureFlag(
            @org.springframework.web.bind.annotation.PathVariable String key,
            @org.springframework.web.bind.annotation.RequestParam boolean enabled) {
        featureFlagService.updateFeatureFlag(key, enabled);
        return ResponseEntity.ok(ApiResponse.<Boolean>builder()
                .success(true)
                .message("Feature flag updated successfully")
                .data(enabled)
                .build());
    }
}
