package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.service.GoogleAuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Endpoint xử lý đăng nhập bằng Google Sign In.
 * Flutter gọi sau khi lấy được Google ID Token.
 */
@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1GoogleAuthController {

    private final GoogleAuthService googleAuthService;

    /**
     * POST /v1/auth/google
     * Body: { "idToken": "<Google ID Token từ flutter google_sign_in>" }
     * Response: AuthResponse (token, refreshToken, user)
     */
    @PostMapping("/google")
    public ResponseEntity<?> loginWithGoogle(@RequestBody Map<String, String> body) {
        String idToken = body.get("idToken");
        if (idToken == null || idToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Thiếu Google ID Token"
            ));
        }

        AuthResponse response = googleAuthService.loginWithGoogle(idToken);
        return ResponseEntity.ok(response);
    }
}
