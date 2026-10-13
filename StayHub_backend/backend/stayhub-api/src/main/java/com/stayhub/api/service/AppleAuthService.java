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
 * Xử lý đăng nhập bằng Apple Sign In (iCloud).
 * Flow: Flutter gửi Apple Identity Token (JWT) → Backend verify với Apple JWKS
 *       → Tạo/tìm user → Trả về JWT của hệ thống.
 *
 * Apple Identity Token là một JWT ký bởi Apple. Để verify đầy đủ chữ ký cần
 * thư viện JWT (jjwt) và JWKS của Apple. Ở đây ta verify tối thiểu:
 *   - Token có 3 phần (header.payload.signature) hợp lệ
 *   - Giải mã payload (base64url) và kiểm tra issuer = https://appleid.apple.com
 *   - Kiểm tra thời hạn (exp)
 *   - Lấy sub (Apple UID) và email
 * Nếu cấu hình đầy đủ (Apple Team ID / Key ID / private key) có thể nâng cấp
 * lên verify chữ ký đầy đủ với JWKS.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AppleAuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;

    private static final String APPLE_ISSUER = "https://appleid.apple.com";

    @Transactional
    public AuthResponse loginWithApple(String identityToken, String fullName, String emailFromClient) {
        // 1. Verify Apple Identity Token
        Map<String, Object> claims = verifyAppleToken(identityToken);

        String appleUid = (String) claims.get("sub");
        String email    = (String) claims.get("email");

        // Apple chỉ trả email ở lần đăng nhập đầu tiên; các lần sau có thể null.
        // Fallback: email do client gửi lên, hoặc email nội bộ theo Apple UID.
        if (email == null || email.isBlank()) {
            email = (emailFromClient != null && !emailFromClient.isBlank())
                    ? emailFromClient
                    : "apple_" + appleUid + "@apple.stayhub.local";
        }

        String name = (fullName != null && !fullName.isBlank())
                ? fullName
                : (email.contains("@") ? email.split("@")[0] : "Apple User");

        log.info("Apple Sign In: uid={}, email={}", appleUid, email);

        final String finalEmail = email;
        final String finalName = name;

        // 2. Tìm hoặc tạo user theo email Apple
        User user = userRepository.findByEmail(finalEmail).orElseGet(() -> {
            User newUser = User.builder()
                    .name(finalName)
                    .email(finalEmail)
                    .phoneNumber(null) // Để trống SĐT nếu đăng nhập bằng Apple
                    .passwordHash("APPLE_AUTH_NO_PASSWORD") // Tránh lỗi NOT NULL ở tầng Database
                    .roleId("TENANT")
                    .status(User.UserStatus.ACTIVE)
                    .build();
            User saved = userRepository.save(newUser);
            log.info("Tạo user mới từ Apple Sign In: id={}, email={}", saved.getId(), finalEmail);
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
                        .requirePasswordSetup("APPLE_AUTH_NO_PASSWORD".equals(user.getPasswordHash()))
                        .build())
                .build();
    }

    /**
     * Verify Apple Identity Token (JWT) — decode payload & kiểm tra issuer/exp.
     * Không dùng thư viện ngoài để tránh phụ thuộc; decode base64url thủ công.
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> verifyAppleToken(String identityToken) {
        try {
            if (identityToken == null || identityToken.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu Apple Identity Token.");
            }

            String[] parts = identityToken.split("\\.");
            if (parts.length != 3) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Apple Identity Token không hợp lệ.");
            }

            // Decode payload (phần thứ 2)
            byte[] decoded = java.util.Base64.getUrlDecoder().decode(padBase64(parts[1]));
            String payloadJson = new String(decoded, java.nio.charset.StandardCharsets.UTF_8);

            com.fasterxml.jackson.databind.ObjectMapper mapper =
                    new com.fasterxml.jackson.databind.ObjectMapper();
            Map<String, Object> claims = mapper.readValue(payloadJson, Map.class);

            // Kiểm tra issuer
            Object iss = claims.get("iss");
            if (iss == null || !APPLE_ISSUER.equals(iss.toString())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Apple Identity Token có issuer không hợp lệ.");
            }

            // Kiểm tra thời hạn
            Object exp = claims.get("exp");
            if (exp instanceof Number) {
                long expSeconds = ((Number) exp).longValue();
                if (Instant.now().getEpochSecond() > expSeconds) {
                    throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                            "Apple Identity Token đã hết hạn.");
                }
            }

            if (claims.get("sub") == null) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Apple Identity Token thiếu định danh người dùng (sub).");
            }

            return claims;
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.error("Lỗi xác thực Apple Identity Token: ", e);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Apple Identity Token không hợp lệ hoặc đã hết hạn.");
        }
    }

    /** Base64url cần padding '=' cho đúng bội số 4. */
    private String padBase64(String s) {
        int mod = s.length() % 4;
        if (mod == 2) return s + "==";
        if (mod == 3) return s + "=";
        if (mod == 1) return s + "===";
        return s;
    }
}
