package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.service.WhatsAppAuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1WhatsAppAuthController {

    private final WhatsAppAuthService whatsAppAuthService;

    @PostMapping("/whatsapp")
    public ResponseEntity<?> loginWithWhatsApp(@RequestBody Map<String, String> body) {
        String phoneToken = body.get("phoneToken");
        if (phoneToken == null || phoneToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Thiếu mã xác thực WhatsApp"
            ));
        }

        AuthResponse response = whatsAppAuthService.loginWithWhatsApp(phoneToken);
        return ResponseEntity.ok(response);
    }
}
