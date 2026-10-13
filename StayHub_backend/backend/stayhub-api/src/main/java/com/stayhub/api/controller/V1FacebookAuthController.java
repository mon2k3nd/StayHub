package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.service.FacebookAuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Endpoint xử lý đăng nhập bằng Facebook Sign In.
 * Flutter gọi sau khi lấy được Facebook Access Token.
 */
@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1FacebookAuthController {

    private final FacebookAuthService facebookAuthService;

    /**
     * POST /v1/auth/facebook
     * Body: { "accessToken": "<Facebook Access Token từ flutter_facebook_auth>" }
     * Response: AuthResponse (token, refreshToken, user)
     */
    @PostMapping("/facebook")
    public ResponseEntity<?> loginWithFacebook(@RequestBody Map<String, String> body) {
        String accessToken = body.get("accessToken");
        if (accessToken == null || accessToken.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Thiếu Facebook Access Token"
            ));
        }

        AuthResponse response = facebookAuthService.loginWithFacebook(accessToken);
        return ResponseEntity.ok(response);
    }
}
