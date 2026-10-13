package com.stayhub.api.controller;

import com.stayhub.api.dto.request.LoginRequest;
import com.stayhub.api.dto.request.RegisterRequest;
import com.stayhub.api.dto.request.SendOtpRequest;
import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.dto.response.SendOtpResponse;
import com.stayhub.api.service.AuthService;
import com.stayhub.api.service.OtpService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final OtpService otpService;

    @PostMapping("/send-otp")
    public ResponseEntity<SendOtpResponse> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        return ResponseEntity.ok(otpService.sendOtp(request));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<com.stayhub.api.dto.response.VerifyOtpResponse> verifyOtp(
            @Valid @RequestBody com.stayhub.api.dto.request.VerifyOtpRequest request) {
        return ResponseEntity.ok(otpService.verifyOtpAndGetToken(request));
    }

    @PostMapping("/phone-verify")
    public ResponseEntity<com.stayhub.api.dto.response.VerifyOtpResponse> verifyPhone(
            @Valid @RequestBody com.stayhub.api.dto.request.PhoneVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyPhoneAndGetToken(request));
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");
        return ResponseEntity.ok(authService.refreshAccessToken(refreshToken));
    }
}
