package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.AiDescriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiDescriptionService aiDescriptionService;

    @GetMapping("/generate-description")
    public ResponseEntity<ApiResponse<String>> generateDescription(
            @RequestParam Long roomId,
            @RequestParam(defaultValue = "CHUYEN_NGHIEP") String tone) {
        
        String generatedContent = aiDescriptionService.generateDescription(roomId, tone);
        return ResponseEntity.ok(ApiResponse.<String>builder()
                .success(true)
                .data(generatedContent)
                .build());
    }
}
