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
 * Xử lý đăng nhập bằng Google Sign In.
 * Sử dụng Google tokeninfo API để verify ID Token — không cần Firebase service account file.
 * Flow: Flutter gửi Google ID Token → Backend verify với Google API
 *       → Tạo/tìm user → Trả về JWT của hệ thống.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GoogleAuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    private static final String GOOGLE_TOKEN_INFO_URL =
            "https://oauth2.googleapis.com/tokeninfo?id_token=";

    @Transactional
    public AuthResponse loginWithGoogle(String idToken) {
        // 1. Verify Google ID Token với Google tokeninfo API (không cần service account)
        Map<String, Object> tokenInfo = verifyGoogleToken(idToken);

        String googleUid     = (String) tokenInfo.get("sub");
        String email         = (String) tokenInfo.get("email");
        String name          = (String) tokenInfo.get("name");
        String emailVerified = (String) tokenInfo.get("email_verified");

        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Tài khoản Google không có email. Vui lòng dùng tài khoản khác.");
        }

        if (!"true".equalsIgnoreCase(emailVerified)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Email Google chưa được xác minh.");
        }

        log.info("Google Sign In: uid={}, email={}", googleUid, email);

        // 2. Tìm hoặc tạo user theo email Google
        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = User.builder()
                    .name(name != null && !name.isBlank() ? name : email.split("@")[0])
                    .email(email)
                    .phoneNumber(null) // Để trống SĐT nếu đăng nhập bằng Google
                    .passwordHash("GOOGLE_AUTH_NO_PASSWORD") // Tránh lỗi NOT NULL ở tầng Database
                    .roleId("TENANT")
                    .status(User.UserStatus.ACTIVE)
                    .build();
            User saved = userRepository.save(newUser);
            log.info("Tạo user mới từ Google Sign In: id={}, email={}", saved.getId(), email);
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

        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), safePackageId);
        String refreshTokenString = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), safePackageId);

        // 5. Lưu Refresh Token
        refreshTokenRepository.deleteByUserId(user.getId());
        RefreshToken refreshTokenEntity = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshTokenString)
                .expiryDate(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        refreshTokenRepository.save(refreshTokenEntity);

        // 6. Build response (cùng format với login thường)
        return AuthResponse.builder()
                .token(accessToken)
                .refreshToken(refreshTokenString)
                .user(
                        AuthResponse.UserPayload.builder()
                                .id(user.getId())
                                .roleId(user.getRoleId())
                                .packageId(safePackageId)
                                .fullName(user.getName())
                                .email(user.getEmail())
                                .phone(user.getPhoneNumber())
                                .status(user.getStatus() != null ? user.getStatus().name() : "ACTIVE")
                                .ownerStatus(user.getOwnerProfile() != null
                                        && user.getOwnerProfile().getOwnerStatus() != null
                                        ? user.getOwnerProfile().getOwnerStatus().name()
                                        : "PENDING_VERIFICATION")
                                .requirePasswordSetup("GOOGLE_AUTH_NO_PASSWORD".equals(user.getPasswordHash()))
                                .build()
                )
                .build();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> verifyGoogleToken(String idToken) {
        try {
            Map<String, Object> response = restTemplate.getForObject(
                    GOOGLE_TOKEN_INFO_URL + idToken,
                    Map.class
            );
            if (response == null || response.containsKey("error_description")) {
                String error = response != null
                        ? (String) response.get("error_description")
                        : "null response";
                log.warn("Google tokeninfo rejected: {}", error);
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Google ID Token không hợp lệ hoặc đã hết hạn.");
            }
            return response;
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Google tokeninfo call failed: {}", e.getMessage());
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Không thể xác minh Google token. Vui lòng thử lại.");
        }
    }
}
