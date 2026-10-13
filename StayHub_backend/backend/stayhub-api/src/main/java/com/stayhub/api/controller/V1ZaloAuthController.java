package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.service.ZaloAuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Endpoint xử lý đăng nhập bằng Zalo.
 * Flutter gọi sau khi lấy được Zalo Access Token.
 */
@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1ZaloAuthController {

    private final ZaloAuthService zaloAuthService;

    /**
     * POST /v1/auth/zalo
     * Body: { "accessToken": "<Zalo Access Token>" }
     * Response: AuthResponse (token, refreshToken, user)
     */
    @PostMapping("/zalo")
    public ResponseEntity<?> loginWithZalo(@RequestBody Map<String, String> body) {
        String accessToken = body.get("accessToken");
        if (accessToken == null || accessToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Thiếu Zalo Access Token"
            ));
        }

        AuthResponse response = zaloAuthService.loginWithZalo(accessToken);
        return ResponseEntity.ok(response);
    }
}
