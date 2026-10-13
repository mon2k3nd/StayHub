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
 * Xử lý đăng nhập bằng Facebook Sign In.
 * Flow: Flutter gửi Facebook Access Token → Backend verify với Facebook Graph API
 *       → Tạo/tìm user → Trả về JWT của hệ thống.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FacebookAuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    private static final String FACEBOOK_GRAPH_API_URL =
            "https://graph.facebook.com/v19.0/me?fields=id,name,email,picture&access_token=";

    @Transactional
    public AuthResponse loginWithFacebook(String accessToken) {
        // 1. Verify Facebook Access Token với Graph API
        Map<String, Object> userInfo = verifyFacebookToken(accessToken);

        String facebookUid = (String) userInfo.get("id");
        String email       = (String) userInfo.get("email");
        String name        = (String) userInfo.get("name");

        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Tài khoản Facebook không cung cấp email. Vui lòng dùng tài khoản khác hoặc kiểm tra lại quyền.");
        }

        log.info("Facebook Sign In: uid={}, email={}", facebookUid, email);

        // 2. Tìm hoặc tạo user theo email Facebook
        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = User.builder()
                    .name(name != null && !name.isBlank() ? name : email.split("@")[0])
                    .email(email)
                    .phoneNumber(null) // Để trống SĐT nếu đăng nhập bằng Facebook
                    .passwordHash("FACEBOOK_AUTH_NO_PASSWORD") // Tránh lỗi NOT NULL ở tầng Database
                    .roleId("TENANT")
                    .status(User.UserStatus.ACTIVE)
                    .build();
            User saved = userRepository.save(newUser);
            log.info("Tạo user mới từ Facebook Sign In: id={}, email={}", saved.getId(), email);
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
                        .requirePasswordSetup("FACEBOOK_AUTH_NO_PASSWORD".equals(user.getPasswordHash()))
                        .build())
                .build();
    }

    private Map<String, Object> verifyFacebookToken(String accessToken) {
        try {
            // Gọi Facebook Graph API
            @SuppressWarnings("unchecked")
            org.springframework.http.ResponseEntity<Map> response = restTemplate.getForEntity(
                    FACEBOOK_GRAPH_API_URL + accessToken, Map.class);
            return response.getBody();
        } catch (Exception e) {
            log.error("Lỗi xác thực Facebook Access Token: ", e);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Facebook Token không hợp lệ hoặc đã hết hạn.");
        }
    }
}
