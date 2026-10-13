package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.service.AppleAuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Endpoint xử lý đăng nhập bằng Apple Sign In (iCloud).
 * Flutter gọi sau khi lấy được Apple Identity Token.
 */
@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1AppleAuthController {

    private final AppleAuthService appleAuthService;

    /**
     * POST /v1/auth/apple
     * Body: { "identityToken": "<Apple Identity Token>",
     *         "fullName": "<optional>", "email": "<optional>" }
     * Response: AuthResponse (token, refreshToken, user)
     */
    @PostMapping("/apple")
    public ResponseEntity<?> loginWithApple(@RequestBody Map<String, String> body) {
        String identityToken = body.get("identityToken");
        if (identityToken == null || identityToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Thiếu Apple Identity Token"
            ));
        }

        String fullName = body.get("fullName");
        String email = body.get("email");

        AuthResponse response = appleAuthService.loginWithApple(identityToken, fullName, email);
        return ResponseEntity.ok(response);
    }
}
