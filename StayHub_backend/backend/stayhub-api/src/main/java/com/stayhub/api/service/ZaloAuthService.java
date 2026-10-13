package com.stayhub.api.service;

import com.stayhub.api.config.JwtUtil;
import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.entity.RefreshToken;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.RefreshTokenRepository;
import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;

/**
 * Xử lý đăng nhập bằng Zalo.
 * Flow: Flutter gửi Zalo Access Token → Backend verify với Zalo Graph API
 *       → Tạo/tìm user → Trả về JWT của hệ thống.
 *
 * Zalo Open API: https://graph.zalo.me/v2.0/me?fields=id,name,picture
 * Header: access_token: <Zalo Access Token>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ZaloAuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    private static final String ZALO_GRAPH_API_URL =
            "https://graph.zalo.me/v2.0/me?fields=id,name,picture,email";

    @Transactional
    public AuthResponse loginWithZalo(String accessToken) {
        // 1. Verify Zalo Access Token với Zalo Graph API
        Map<String, Object> userInfo = verifyZaloToken(accessToken);

        String zaloUid = (String) userInfo.get("id");
        String name    = (String) userInfo.get("name");
        String email   = (String) userInfo.get("email");

        // Zalo thường không trả email (tuỳ scope). Nếu thiếu, tạo email nội bộ
        // theo Zalo UID để đảm bảo định danh duy nhất và không vi phạm NOT NULL.
        if (email == null || email.isBlank()) {
            email = "zalo_" + zaloUid + "@zalo.stayhub.local";
        }

        log.info("Zalo Sign In: uid={}, email={}", zaloUid, email);

        final String finalEmail = email;

        // 2. Tìm hoặc tạo user theo email Zalo
        User user = userRepository.findByEmail(finalEmail).orElseGet(() -> {
            User newUser = User.builder()
                    .name(name != null && !name.isBlank() ? name : "Zalo User")
                    .email(finalEmail)
                    .phoneNumber(null) // Để trống SĐT nếu đăng nhập bằng Zalo
                    .passwordHash("ZALO_AUTH_NO_PASSWORD") // Tránh lỗi NOT NULL ở tầng Database
                    .roleId("TENANT")
                    .status(User.UserStatus.ACTIVE)
                    .build();
            User saved = userRepository.save(newUser);
            log.info("Tạo user mới từ Zalo Sign In: id={}, email={}", saved.getId(), finalEmail);
            return saved;
        });

        // 3. Kiểm tra trạng thái tài khoản
        if (user.getStatus() == User.UserStatus.LOCKED) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản của bạn đã bị khóa.");
        }

        // 4. Tạo JWT tokens
        String safePackageId = user.getOwnerProfile() != null
                && user.getOwnerProfile().getPackageId() != null
                ? user.getOwnerProfile().getPackageId() : "FREE";

        String systemAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), safePackageId);
        String refreshTokenString = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), safePackageId);

        // 5. Lưu Refresh Token
        refreshTokenRepository.deleteByUserId(user.getId());
        RefreshToken refreshTokenEntity = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshTokenString)
                .expiryDate(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        refreshTokenRepository.save(refreshTokenEntity);

        // 6. Trả về
        return AuthResponse.builder()
                .token(systemAccessToken)
                .refreshToken(refreshTokenString)
                .user(AuthResponse.UserPayload.builder()
                        .id(user.getId())
                        .fullName(user.getName())
                        .email(user.getEmail())
                        .phone(user.getPhoneNumber())
                        .roleId(user.getRoleId())
                        .status(user.getStatus().name())
                        .avatarUrl(user.getAvatarUrl())
                        .requirePasswordSetup("ZALO_AUTH_NO_PASSWORD".equals(user.getPasswordHash()))
                        .build())
                .build();
    }

    private Map<String, Object> verifyZaloToken(String accessToken) {
        try {
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("access_token", accessToken);
            org.springframework.http.HttpEntity<Void> entity =
                    new org.springframework.http.HttpEntity<>(headers);

            @SuppressWarnings("unchecked")
            org.springframework.http.ResponseEntity<Map> response = restTemplate.exchange(
                    ZALO_GRAPH_API_URL,
                    org.springframework.http.HttpMethod.GET,
                    entity,
                    Map.class);

            Map<String, Object> body = response.getBody();
            if (body == null || body.get("id") == null) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Zalo Access Token không hợp lệ hoặc đã hết hạn.");
            }
            return body;
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.error("Lỗi xác thực Zalo Access Token: ", e);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Zalo Token không hợp lệ hoặc đã hết hạn.");
        }
    }
}
