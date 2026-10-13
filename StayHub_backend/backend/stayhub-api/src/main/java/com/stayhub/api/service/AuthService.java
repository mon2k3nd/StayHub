package com.stayhub.api.service;

import com.stayhub.api.config.JwtUtil;
import com.stayhub.api.dto.request.LoginRequest;
import com.stayhub.api.dto.request.PhoneVerifyRequest;
import com.stayhub.api.dto.request.RegisterRequest;
import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.dto.response.VerifyOtpResponse;
import com.stayhub.api.entity.Otp;
import com.stayhub.api.entity.RefreshToken;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.RefreshTokenRepository;
import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.stayhub.api.exception.WrongPasswordException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenRepository refreshTokenRepository;

    /**
     * Xác thực Số điện thoại qua Firebase Phone Auth và tạo registration token.
     * Firebase đã xác thực OTP SMS, backend chỉ cần kiểm tra phone chưa tồn tại rồi tạo token.
     */
    public VerifyOtpResponse verifyPhoneAndGetToken(PhoneVerifyRequest request) {
        // Định dạng chuẩn hoá: 0912345678 hoặc +84912345678 → 0912345678 (bỏ prefix +84)
        String phoneNumber = request.getPhoneNumber();
        // Guard: thiếu số điện thoại -> 400 rõ ràng thay vì NPE -> 500.
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Vui lòng cung cấp số điện thoại"
            );
        }
        phoneNumber = phoneNumber.trim();
        if (phoneNumber.startsWith("+84")) {
            phoneNumber = "0" + phoneNumber.substring(3);
        }

        // Kiểm tra số điện thoại đã tồn tại chưa
        if (userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Số điện thoại này đã được đăng ký"
            );
        }

        // Firebase đã xác thực thành công, tạo registrationToken
        String token = jwtUtil.generateRegistrationToken(phoneNumber);

        log.info("[PhoneAuth] Firebase xác thực SĐT {} thành công (uid={})",
                phoneNumber.substring(0, Math.min(5, phoneNumber.length())) + "***",
                request.getFirebaseUid());

        return VerifyOtpResponse.builder()
                .success(true)
                .message("Xác thực số điện thoại thành công")
                .registrationToken(token)
                .build();
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Mật khẩu xác nhận không khớp"
            );
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Email đã được đăng ký"
            );
        }

        if (request.getPhoneNumber() != null && userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Số điện thoại đã được đăng ký"
            );
        }

        String verifiedTarget = jwtUtil.validateAndGetTargetFromRegistrationToken(request.getRegistrationToken());

        if (!verifiedTarget.equals(request.getEmail()) && 
            (request.getPhoneNumber() == null || !verifiedTarget.equals(request.getPhoneNumber()))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Email hoặc số điện thoại không khớp với mã xác thực"
            );
        }

        User user = User.builder()
                .name(request.getFullName())
                .email(request.getEmail())
                .phoneNumber(request.getPhoneNumber())
                .passwordHash(
                        passwordEncoder.encode(request.getPassword())
                )
                .roleId("TENANT")
                .status(User.UserStatus.ACTIVE)
                .build();

        user = userRepository.save(user);

        log.info(
                "Người dùng mới đăng ký: id={}, phone={}",
                user.getId(),
                user.getPhoneNumber()
        );

        String safePackageId = user.getOwnerProfile() != null && user.getOwnerProfile().getPackageId() != null ? user.getOwnerProfile().getPackageId() : "FREE";
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), safePackageId);
        String refreshTokenString = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), safePackageId);

        // Lưu Refresh Token vào DB
        RefreshToken refreshTokenEntity = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshTokenString)
                .expiryDate(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        refreshTokenRepository.save(refreshTokenEntity);

        return buildResponse(accessToken, refreshTokenString, user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {

        // Guard: nếu client gửi thiếu emailOrPhone (null/rỗng) thì trả 400 rõ ràng
        // thay vì ném NullPointerException -> 500 "Lỗi không mong đợi".
        String identifier = request.getEmailOrPhone();
        if (identifier == null || identifier.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Vui lòng nhập email hoặc số điện thoại"
            );
        }
        identifier = identifier.trim();

        boolean isEmail = identifier.contains("@");

        User user =
                isEmail
                        ? userRepository.findByEmail(
                                request.getEmailOrPhone())
                        .orElseThrow(() ->
                                     new ResponseStatusException(
                                             HttpStatus.UNAUTHORIZED,
                                             "Email/SĐT hoặc mật khẩu không đúng"))
                        : userRepository.findByPhoneNumber(
                                request.getEmailOrPhone())
                        .orElseThrow(() ->
                                     new ResponseStatusException(
                                             HttpStatus.UNAUTHORIZED,
                                             "Email/SĐT hoặc mật khẩu không đúng"));

        if (user.getStatus() == User.UserStatus.LOCKED) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Tài khoản của bạn đã bị khóa."
            );
        }

        if (!passwordEncoder.matches(
                request.getPassword(),
                user.getPasswordHash())) {

            throw new WrongPasswordException(
                    "Email/SĐT hoặc mật khẩu không đúng",
                    user.getName(),
                    user.getAvatarUrl()
            );
        }

        log.info(
                "Đăng nhập thành công: userId={}",
                user.getId()
        );

        String safePackageId = user.getOwnerProfile() != null && user.getOwnerProfile().getPackageId() != null ? user.getOwnerProfile().getPackageId() : "FREE";
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), safePackageId);
        String refreshTokenString = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), safePackageId);

        // Lưu Refresh Token vào DB
        refreshTokenRepository.deleteByUserId(user.getId());
        RefreshToken refreshTokenEntity = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshTokenString)
                .expiryDate(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        refreshTokenRepository.save(refreshTokenEntity);

        return buildResponse(accessToken, refreshTokenString, user);
    }

    @Transactional
    public AuthResponse refreshAccessToken(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh Token không hợp lệ");
        }

        RefreshToken dbToken = refreshTokenRepository.findByToken(refreshToken)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh Token không tồn tại hoặc đã bị thu hồi"));

        if (dbToken.getExpiryDate().isBefore(Instant.now())) {
            refreshTokenRepository.delete(dbToken);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh Token đã hết hạn");
        }

        if (!jwtUtil.isTokenValid(refreshToken)) {
            refreshTokenRepository.delete(dbToken);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh Token không hợp lệ");
        }

        Long userId = jwtUtil.extractUserId(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng"));

        String safePackageId = user.getOwnerProfile() != null && user.getOwnerProfile().getPackageId() != null ? user.getOwnerProfile().getPackageId() : "FREE";
        String newAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), safePackageId);
        String newRefreshToken = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), safePackageId);

        refreshTokenRepository.delete(dbToken);
        RefreshToken newDbToken = RefreshToken.builder()
                .userId(user.getId())
                .token(newRefreshToken)
                .expiryDate(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        refreshTokenRepository.save(newDbToken);

        return buildResponse(newAccessToken, newRefreshToken, user);
    }

    private AuthResponse buildResponse(
            String token,
            String refreshToken,
            User user) {

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .user(
                        AuthResponse.UserPayload.builder()
                                .id(user.getId())
                                .roleId(user.getRoleId())
                                .packageId(user.getOwnerProfile() != null && user.getOwnerProfile().getPackageId() != null ? user.getOwnerProfile().getPackageId() : "FREE")
                                .fullName(user.getName())
                                .email(user.getEmail())
                                .phone(user.getPhoneNumber())
                                .status(user.getStatus() != null ? user.getStatus().name() : "PENDING_VERIFICATION")
                                .ownerStatus(user.getOwnerProfile() != null && user.getOwnerProfile().getOwnerStatus() != null ? user.getOwnerProfile().getOwnerStatus().name() : "PENDING_VERIFICATION")
                                .build()
                )
                .build();
    }
}