package com.stayhub.api.controller;

import com.stayhub.api.dto.request.SendOtpRequest;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.SendOtpResponse;
import com.stayhub.api.entity.Otp;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.OtpService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
public class V1AuthController {

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final PasswordEncoder passwordEncoder;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getMe(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        Long userId = (Long) auth.getPrincipal();
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("User not found"));
        }
        return ResponseEntity.ok(ApiResponse.ok(user));
    }

    public record ForgotPasswordRequest(String email) {}
    public record ResetPasswordRequest(String email, String otp, String newPassword) {}
    public record FcmTokenRequest(String token) {}

    /**
     * Gửi OTP về email để xác minh quên mật khẩu
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Object>> forgotPassword(@RequestBody ForgotPasswordRequest body) {
        String email = body.email();
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Vui lòng nhập email"));
        }

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            // Không tiết lộ email có tồn tại hay không (bảo mật)
            return ResponseEntity.ok(ApiResponse.ok("Nếu email tồn tại, mã OTP đã được gửi"));
        }

        SendOtpRequest otpReq = new SendOtpRequest();
        otpReq.setTarget(email);
        otpReq.setChannel(Otp.Channel.email);
        otpReq.setType(Otp.OtpType.reset_password);

        SendOtpResponse otpRes = otpService.sendOtp(otpReq);

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "message", "Mã OTP đã được gửi đến email của bạn",
                "devOtp", otpRes.getDevOtp() != null ? otpRes.getDevOtp() : ""
        )));
    }

    /**
     * Verify OTP và cập nhật mật khẩu mới
     */
    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Object>> resetPassword(@RequestBody ResetPasswordRequest body) {
        String email = body.email();
        String otp = body.otp();
        String newPassword = body.newPassword();

        if (email == null || otp == null || newPassword == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Thiếu thông tin"));
        }

        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Mật khẩu phải có ít nhất 6 ký tự"));
        }

        // Verify OTP
        try {
            otpService.verifyAndMarkUsed(email, otp, Otp.OtpType.reset_password);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Mã OTP không hợp lệ hoặc đã hết hạn"));
        }

        // Cập nhật mật khẩu
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Không tìm thấy tài khoản"));
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.ok("Mật khẩu đã được cập nhật thành công"));
    }

    /**
     * Lưu FCM token của thiết bị để nhận Push Notification
     * Gọi sau khi đăng nhập thành công hoặc khi token được làm mới
     */
    @PutMapping("/fcm-token")
    public ResponseEntity<ApiResponse<String>> updateFcmToken(
            Authentication auth,
            @RequestBody FcmTokenRequest body) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("Vui lòng đăng nhập"));
        }
        String token = body.token();
        if (token == null || token.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Token không hợp lệ"));
        }
        Long userId = (Long) auth.getPrincipal();
        userRepository.findById(userId).ifPresent(user -> {
            user.setFcmToken(token);
            userRepository.save(user);
        });
        return ResponseEntity.ok(ApiResponse.ok("FCM token đã được cập nhật"));
    }
}
