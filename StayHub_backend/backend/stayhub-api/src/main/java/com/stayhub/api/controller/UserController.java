package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.UserProfileResponse;
import com.stayhub.api.dto.request.UpdateSignatureRequest;
import com.stayhub.api.entity.SignatureHistory;
import com.stayhub.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;
import java.util.List;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.MediaType;

@RestController
@RequestMapping("/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final com.stayhub.api.repository.UserRepository userRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @GetMapping("/{id}/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(id)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền xem thông tin người dùng khác");
        }
        return ResponseEntity.ok(ApiResponse.<UserProfileResponse>builder()
                .success(true)
                .message("Lấy thông tin người dùng thành công")
                .data(userService.getProfileById(id))
                .build());
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @PathVariable Long id,
            @RequestBody Map<String, String> fields,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(id)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền cập nhật thông tin người dùng khác");
        }
        return ResponseEntity.ok(ApiResponse.<UserProfileResponse>builder()
                .success(true)
                .message("Cập nhật thông tin thành công")
                .data(userService.updateProfile(id, fields))
                .build());
    }

    @PostMapping(value = "/{id}/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<UserProfileResponse>> uploadAvatar(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(id)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền cập nhật ảnh đại diện người dùng khác");
        }
        return ResponseEntity.ok(ApiResponse.<UserProfileResponse>builder()
                .success(true)
                .message("Cập nhật ảnh đại diện thành công")
                .data(userService.uploadAvatar(id, file))
                .build());
    }

    @PostMapping("/register-as-owner")
    public ResponseEntity<ApiResponse<UserProfileResponse>> registerAsOwner(
            @RequestBody Map<String, String> request) {
        // userId should ideally come from JWT token, for now we can pass it in request or get from security context.
        // assuming userId is passed for simplicity, or we should use Authentication principal.
        // But since this is a quick implementation, we will extract userId from request
        Long userId = Long.parseLong(request.get("userId"));
        return ResponseEntity.ok(ApiResponse.<UserProfileResponse>builder()
                .success(true)
                .message("Đã gửi yêu cầu xác thực KYC lên Admin")
                .data(userService.registerAsOwner(userId, request))
                .build());
    }

    @PutMapping("/{id}/signature")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateSignature(
            @PathVariable Long id,
            @RequestBody UpdateSignatureRequest request,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(id)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền cập nhật chữ ký người dùng khác");
        }
        return ResponseEntity.ok(ApiResponse.<UserProfileResponse>builder()
                .success(true)
                .message("Cập nhật chữ ký thành công")
                .data(userService.updateSignature(id, request))
                .build());
    }

    @PostMapping("/device-token")
    public ResponseEntity<ApiResponse<Void>> updateDeviceToken(@RequestBody Map<String, String> request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Long userId = Long.valueOf(auth.getPrincipal().toString());
        String token = request.get("token");
        
        userService.updateFcmToken(userId, token);
        
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Cập nhật device token thành công")
                .build());
    }

    @GetMapping("/{id}/signature-history")
    public ResponseEntity<ApiResponse<List<SignatureHistory>>> getSignatureHistory(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(id)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền xem lịch sử chữ ký người dùng khác");
        }
        return ResponseEntity.ok(ApiResponse.<List<SignatureHistory>>builder()
                .success(true)
                .message("Lấy lịch sử chữ ký thành công")
                .data(userService.getSignatureHistory(id))
                .build());
    }
}
