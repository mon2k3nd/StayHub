package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.KycRequestRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.KycService;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class KycServiceImpl implements KycService {

    private final KycRequestRepository kycRequestRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    private static final String UPLOAD_DIR = "uploads/kyc/";

    @Override
    @Transactional
    public KycRequest submitRequest(Long userId, String branchName, String businessAddress,
                                    MultipartFile cccdFront, MultipartFile cccdBack,
                                    MultipartFile businessLicense) {
        // Kiểm tra đã có yêu cầu đang chờ chưa
        if (kycRequestRepository.existsByUserIdAndStatus(userId, KycStatus.PENDING)) {
            throw new IllegalStateException("Bạn đã có yêu cầu đang chờ xét duyệt!");
        }

        // Áp dụng quy tắc Dual Address System 2026: Nội suy về 3 cấp cho eKYC
        com.stayhub.api.service.AddressMapper.Address3Tier mappedAddress = com.stayhub.api.service.AddressMapper.mapTo3Tier(businessAddress);
        String finalBusinessAddress = mappedAddress.toFullAddress();

        KycRequest kyc = KycRequest.builder()
                .userId(userId)
                .branchName(branchName)
                .businessAddress(finalBusinessAddress)
                .cccdFrontUrl(saveFile(cccdFront, "cccd_front"))
                .cccdBackUrl(saveFile(cccdBack, "cccd_back"))
                .businessLicenseUrl(saveFile(businessLicense, "license"))
                .status(KycStatus.PENDING)
                .build();

        // Đánh dấu user đang chờ duyệt
        userRepository.findById(userId).ifPresent(user -> {
            var ownerProfile = user.getOwnerProfile();
            if (ownerProfile == null) {
                ownerProfile = new com.stayhub.api.entity.OwnerProfile();
                ownerProfile.setUser(user);
                user.setOwnerProfile(ownerProfile);
            }
            ownerProfile.setRequestingOwner(true);
            userRepository.save(user);
        });

        return kycRequestRepository.save(kyc);
    }

    @Override
    public List<KycRequest> getPending() {
        return kycRequestRepository.findByStatus(KycStatus.PENDING);
    }

    @Override
    @Transactional
    public void approve(Long kycId) {
        KycRequest kyc = kycRequestRepository.findById(kycId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy yêu cầu KYC ID: " + kycId));
        kyc.setStatus(KycStatus.APPROVED);
        kyc.setReviewedAt(LocalDateTime.now());
        kycRequestRepository.save(kyc);

        // Nâng cấp role người dùng lên OWNER
        userRepository.findById(kyc.getUserId()).ifPresent(user -> {
            user.setRoleId("OWNER");
            if (user.getOwnerProfile() != null) {
                user.getOwnerProfile().setRequestingOwner(false);
            }
            userRepository.save(user);
        });

        notificationService.send(null, kyc.getUserId(), NotificationScope.INDIVIDUAL,
                "Chúc mừng! Yêu cầu làm Chủ nhà đã được duyệt",
                "Tài khoản của bạn đã được nâng cấp lên Chủ nhà. Hãy đăng xuất và đăng nhập lại để trải nghiệm!",
                NotificationType.KYC_APPROVED, kycId, false, null, null);
    }

    @Override
    @Transactional
    public void reject(Long kycId, String reason) {
        KycRequest kyc = kycRequestRepository.findById(kycId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy yêu cầu KYC ID: " + kycId));
        kyc.setStatus(KycStatus.REJECTED);
        kyc.setAdminNote(reason);
        kyc.setReviewedAt(LocalDateTime.now());
        kycRequestRepository.save(kyc);

        userRepository.findById(kyc.getUserId()).ifPresent(user -> {
            if (user.getOwnerProfile() != null) {
                user.getOwnerProfile().setRequestingOwner(false);
            }
            userRepository.save(user);
        });

        notificationService.send(null, kyc.getUserId(), NotificationScope.INDIVIDUAL,
                "Yêu cầu làm Chủ nhà bị từ chối",
                "Lý do: " + reason + ". Bạn có thể gửi lại yêu cầu sau khi bổ sung hồ sơ.",
                NotificationType.KYC_REJECTED, kycId, false, null, null);
    }

    private String saveFile(MultipartFile file, String prefix) {
        if (file == null || file.isEmpty()) return null;
        try {
            Files.createDirectories(Paths.get(UPLOAD_DIR));
            String filename = prefix + "_" + UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path dest = Paths.get(UPLOAD_DIR + filename);
            Files.write(dest, file.getBytes());
            return "/uploads/kyc/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Lỗi upload file: " + e.getMessage());
        }
    }
}
