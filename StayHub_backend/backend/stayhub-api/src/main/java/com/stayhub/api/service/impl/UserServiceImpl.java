package com.stayhub.api.service.impl;

import com.stayhub.api.config.JwtUtil;
import com.stayhub.api.dto.request.LoginRequest;
import com.stayhub.api.dto.request.RegisterRequest;
import com.stayhub.api.dto.response.LoginResponse;
import com.stayhub.api.dto.response.UserProfileResponse;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.exception.BadRequestException;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.service.UserService;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.stayhub.api.service.CloudStorageService;

import java.util.Map;
import java.util.List;
import com.stayhub.api.entity.SignatureHistory;
import com.stayhub.api.entity.Otp;
import com.stayhub.api.dto.request.UpdateSignatureRequest;
import com.stayhub.api.repository.SignatureHistoryRepository;
import com.stayhub.api.service.OtpService;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final ContractRepository contractRepository;
    private final NotificationService notificationService;
    private final OtpService otpService;
    private final SignatureHistoryRepository signatureHistoryRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final CloudStorageService cloudStorageService;

    public LoginResponse register(RegisterRequest req) {

        if (userRepository.existsByPhoneNumber(req.getPhoneNumber())) {
            throw new BadRequestException("Số điện thoại đã được đăng ký!");
        }

        if (userRepository.existsByEmail(req.getEmail())) {
            throw new BadRequestException("Email đã được đăng ký!");
        }

        User user = User.builder()
                .name(req.getFullName())
                .phoneNumber(req.getPhoneNumber())
                .email(req.getEmail())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .roleId("TENANT")
                .status(User.UserStatus.ACTIVE)
                .build();

        User saved = userRepository.save(user);

        try {
            notificationService.send(
                    null, // System sender
                    saved.getId(),
                    com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "🎉 Chào mừng đến với StayHub!",
                    "Cảm ơn bạn đã tham gia cộng đồng StayHub. Hãy khám phá ngay các phòng trọ và tiện ích tuyệt vời của chúng tôi nhé!",
                    com.stayhub.api.entity.NotificationType.GENERAL,
                    null,
                    false,
                    null,
                    null
            );
        } catch (Exception e) {
            // Ignore if notification fails so registration doesn't rollback
        }

        String token = jwtUtil.generateToken(
                saved.getId(),
                saved.getRoleId(),
                saved.getOwnerProfile() != null && saved.getOwnerProfile().getPackageId() != null ? saved.getOwnerProfile().getPackageId() : "FREE"
        );

        return LoginResponse.builder()
                .accessToken(token)
                .userId(saved.getId())
                .name(saved.getName())
                .phoneNumber(saved.getPhoneNumber())
                .roleId(saved.getRoleId())
                .packageId(saved.getOwnerProfile() != null ? saved.getOwnerProfile().getPackageId() : null)
                .accountStatus(saved.getStatus().name())
                .build();
    }

    public LoginResponse login(LoginRequest req) {

        User user = userRepository.findByPhoneNumber(req.getEmailOrPhone())
                .orElseThrow(() ->
                        new BadRequestException("Số điện thoại không tồn tại!")
                );

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Mật khẩu không đúng!");
        }

        if (user.getStatus() == User.UserStatus.LOCKED) {
            throw new BadRequestException(
                    "Tài khoản của bạn đã bị khóa!"
            );
        }

        String token = jwtUtil.generateToken(
                user.getId(),
                user.getRoleId(),
                user.getOwnerProfile() != null && user.getOwnerProfile().getPackageId() != null ? user.getOwnerProfile().getPackageId() : "FREE"
        );

        return LoginResponse.builder()
                .accessToken(token)
                .userId(user.getId())
                .name(user.getName())
                .phoneNumber(user.getPhoneNumber())
                .roleId(user.getRoleId())
                .packageId(user.getOwnerProfile() != null ? user.getOwnerProfile().getPackageId() : null)
                .accountStatus(user.getStatus().name())
                .build();
    }

    @Override
    public User getById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Không tìm thấy user ID: " + id
                        )
                );
    }

    @Override
    public UserProfileResponse getProfileById(Long id) {
        return UserProfileResponse.from(getById(id));
    }

    @Override
    public UserProfileResponse updateProfile(
            Long userId,
            Map<String, String> fields
    ) {

        User user = getById(userId);

        // Security Guardrail: Chủ nhà đã KYC không được đổi thông tin nhân thân
        boolean isOwnerAndApproved = "OWNER".equals(user.getRoleId())
                && user.getOwnerProfile() != null && user.getOwnerProfile().getOwnerStatus() == com.stayhub.api.entity.OwnerStatus.APPROVED;
        if (isOwnerAndApproved) {
            boolean modifyingIdentity = fields.containsKey("fullName")
                    || fields.containsKey("cccdNumber")
                    || fields.containsKey("hometown");
            if (modifyingIdentity) {
                throw new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.FORBIDDEN,
                        "Tài khoản đã được xác thực KYC. Không thể thay đổi thông tin nhân thân!");
            }
        }

        if (fields.containsKey("fullName")) {
            user.setName(fields.get("fullName"));
        }

        if (fields.containsKey("email")) {

            String newEmail = fields.get("email");

            if (!newEmail.equals(user.getEmail())
                    && userRepository.existsByEmail(newEmail)) {

                throw new BadRequestException(
                        "Email đã được sử dụng!"
                );
            }

            user.setEmail(newEmail);
        }

        var ownerProfile = user.getOwnerProfile();
        var tenantProfile = user.getTenantProfile();

        if (fields.containsKey("bankName") || fields.containsKey("bankAccountNumber") || fields.containsKey("bankAccountName") || fields.containsKey("signature")) {
            if (ownerProfile == null) {
                ownerProfile = new com.stayhub.api.entity.OwnerProfile();
                ownerProfile.setUser(user);
                user.setOwnerProfile(ownerProfile);
            }
            if (fields.containsKey("bankName")) ownerProfile.setBankName(fields.get("bankName"));
            if (fields.containsKey("bankAccountNumber")) ownerProfile.setBankAccountNumber(fields.get("bankAccountNumber"));
            if (fields.containsKey("bankAccountName")) ownerProfile.setBankAccountName(fields.get("bankAccountName"));
            if (fields.containsKey("signature")) ownerProfile.setSignature(fields.get("signature"));
        }

        if (fields.containsKey("cccdNumber") || fields.containsKey("hometown") || fields.containsKey("gender") ||
            fields.containsKey("dateOfBirth") || fields.containsKey("occupation") || fields.containsKey("cccdIssueDate") ||
            fields.containsKey("cccdIssuePlace") || fields.containsKey("emergencyContactName") || fields.containsKey("emergencyContactPhone") ||
            fields.containsKey("vehicleType") || fields.containsKey("licensePlate")) {

            if (tenantProfile == null) {
                tenantProfile = new com.stayhub.api.entity.TenantProfile();
                tenantProfile.setUser(user);
                user.setTenantProfile(tenantProfile);
            }

            if (fields.containsKey("cccdNumber")) tenantProfile.setCccdNumber(fields.get("cccdNumber"));
            if (fields.containsKey("hometown")) tenantProfile.setHometown(fields.get("hometown"));
            if (fields.containsKey("gender")) tenantProfile.setGender(fields.get("gender"));
            if (fields.containsKey("dateOfBirth")) {
                String dobStr = fields.get("dateOfBirth");
                if (dobStr != null && !dobStr.isEmpty()) tenantProfile.setDateOfBirth(java.time.LocalDateTime.parse(dobStr));
                else tenantProfile.setDateOfBirth(null);
            }
            if (fields.containsKey("occupation")) tenantProfile.setOccupation(fields.get("occupation"));
            if (fields.containsKey("cccdIssueDate")) {
                String issueDateStr = fields.get("cccdIssueDate");
                if (issueDateStr != null && !issueDateStr.isEmpty()) tenantProfile.setCccdIssueDate(java.time.LocalDateTime.parse(issueDateStr));
                else tenantProfile.setCccdIssueDate(null);
            }
            if (fields.containsKey("cccdIssuePlace")) tenantProfile.setCccdIssuePlace(fields.get("cccdIssuePlace"));
            if (fields.containsKey("emergencyContactName")) tenantProfile.setEmergencyContactName(fields.get("emergencyContactName"));
            if (fields.containsKey("emergencyContactPhone")) tenantProfile.setEmergencyContactPhone(fields.get("emergencyContactPhone"));
            if (fields.containsKey("vehicleType")) tenantProfile.setVehicleType(fields.get("vehicleType"));
            if (fields.containsKey("licensePlate")) tenantProfile.setLicensePlate(fields.get("licensePlate"));
        }

        if (fields.containsKey("phoneNumber")) {
            String newPhone = fields.get("phoneNumber");
            if (!newPhone.equals(user.getPhoneNumber()) && userRepository.existsByPhoneNumber(newPhone)) {
                throw new BadRequestException("Số điện thoại đã được sử dụng!");
            }
            user.setPhoneNumber(newPhone);
        }

        if (user.getStatus() == com.stayhub.api.entity.User.UserStatus.PENDING_VERIFICATION) {
            if (user.getName() != null && !user.getName().isEmpty() &&
                tenantProfile != null && tenantProfile.getCccdNumber() != null && !tenantProfile.getCccdNumber().isEmpty()) {
                user.setStatus(com.stayhub.api.entity.User.UserStatus.ACTIVE);
            }
        }

        return UserProfileResponse.from(
                userRepository.save(user)
        );
    }

    @Override
    public void changePassword(
            Long userId,
            String oldPassword,
            String newPassword
    ) {

        User user = getById(userId);

        if (!passwordEncoder.matches(
                oldPassword,
                user.getPasswordHash()
        )) {

            throw new BadRequestException(
                    "Mật khẩu cũ không đúng!"
            );
        }

        user.setPasswordHash(
                passwordEncoder.encode(newPassword)
        );

        userRepository.save(user);
    }

    @Override
    public void lockAccount(Long userId) {

        User user = getById(userId);

        user.setStatus(User.UserStatus.LOCKED);

        userRepository.save(user);
    }

    @Override
    public void unlockAccount(Long userId) {

        User user = getById(userId);

        user.setStatus(User.UserStatus.ACTIVE);

        userRepository.save(user);
    }
    @Override
    public User updateFcmToken(Long userId, String fcmToken) {
        User user = getById(userId);
        user.setFcmToken(fcmToken);
        return userRepository.save(user);
    }

    @Override
    public UserProfileResponse registerAsOwner(Long userId, Map<String, String> request) {
        User user = getById(userId);

        // Null-safe: getRequestingOwner() là Boolean (có thể NULL với dữ liệu cũ
        // tạo trước khi field này tồn tại) → dùng Boolean.TRUE.equals() để tránh
        // NullPointerException khi auto-unbox.
        if (user.getOwnerProfile() != null
                && user.getOwnerProfile().getOwnerStatus() == com.stayhub.api.entity.OwnerStatus.PENDING_VERIFICATION
                && Boolean.TRUE.equals(user.getOwnerProfile().getRequestingOwner())) {
            throw new BadRequestException("Hồ sơ đang chờ duyệt. Vui lòng không gửi lại!");
        }

        if (request.containsKey("fullName")) {
            user.setName(request.get("fullName"));
        }
        if (request.containsKey("cccdNumber")) {
            if (user.getTenantProfile() == null) {
                user.setTenantProfile(new com.stayhub.api.entity.TenantProfile());
                user.getTenantProfile().setUser(user);
            }
            user.getTenantProfile().setCccdNumber(request.get("cccdNumber"));
        }
        if (request.containsKey("phoneNumber")) {
            user.setPhoneNumber(request.get("phoneNumber"));
        }

        if (user.getOwnerProfile() == null) {
            user.setOwnerProfile(new com.stayhub.api.entity.OwnerProfile());
            user.getOwnerProfile().setUser(user);
        }
        user.getOwnerProfile().setOwnerStatus(com.stayhub.api.entity.OwnerStatus.PENDING_VERIFICATION);
        user.getOwnerProfile().setRequestingOwner(true);
        userRepository.save(user);

        // Notify Admin
        // create a notification with scope = GLOBAL
        notificationService.send(
                user.getId(), // sender
                null, // receiverId is null for GLOBAL admin notifications, or specifically send to Admin
                com.stayhub.api.entity.NotificationScope.GLOBAL,
                "Yêu cầu duyệt Chủ nhà mới",
                "Người dùng " + user.getName() + " vừa gửi hồ sơ KYC",
                com.stayhub.api.entity.NotificationType.SYSTEM_ALERT,
                null,
                true, // actionable
                com.stayhub.api.entity.NotificationActionStatus.PENDING,
                "{\"endpoint\":\"/v1/admin/owners/" + user.getId() + "/verify\", \"method\":\"PUT\"}"
        );

        return UserProfileResponse.from(user);
    }
    
    @Override
    public UserProfileResponse uploadAvatar(Long userId, MultipartFile file) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
                
        String avatarUrl = cloudStorageService.uploadFile(file);
        user.setAvatarUrl(avatarUrl);
        userRepository.save(user);
        
        return UserProfileResponse.from(user);
    }

    @Override
    public UserProfileResponse updateSignature(Long userId, UpdateSignatureRequest request) {
        User user = getById(userId);

        String signature = user.getOwnerProfile() != null ? user.getOwnerProfile().getSignature() : null;
        if (signature != null && !signature.isEmpty()) {
            if (request.getOtp() == null || request.getOtp().isEmpty()) {
                throw new BadRequestException("Cập nhật chữ ký từ lần thứ 2 trở đi cần mã OTP.");
            }
            // Verify OTP
            boolean verified = false;
            try {
                otpService.verifyAndMarkUsed(user.getPhoneNumber(), request.getOtp(), Otp.OtpType.update_signature);
                verified = true;
            } catch (Exception e) {
                if (user.getEmail() != null && !user.getEmail().isEmpty()) {
                    try {
                        otpService.verifyAndMarkUsed(user.getEmail(), request.getOtp(), Otp.OtpType.update_signature);
                        verified = true;
                    } catch (Exception ex) {
                        // ignored
                    }
                }
            }
            if (!verified) {
                throw new BadRequestException("Mã OTP không hợp lệ hoặc đã hết hạn.");
            }
        }

        if (user.getOwnerProfile() == null) {
            user.setOwnerProfile(new com.stayhub.api.entity.OwnerProfile());
            user.getOwnerProfile().setUser(user);
        }
        user.getOwnerProfile().setSignature(request.getSignature());
        User savedUser = userRepository.save(user);

        signatureHistoryRepository.save(SignatureHistory.builder()
                .userId(savedUser.getId())
                .signature(savedUser.getOwnerProfile().getSignature())
                .build());

        return UserProfileResponse.from(savedUser);
    }

    @Override
    public List<SignatureHistory> getSignatureHistory(Long userId) {
        return signatureHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
}