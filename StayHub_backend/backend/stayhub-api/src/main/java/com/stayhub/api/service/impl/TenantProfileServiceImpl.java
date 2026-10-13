package com.stayhub.api.service.impl;

import com.stayhub.api.entity.KycStatus;
import com.stayhub.api.entity.TenantProfile;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.TenantProfileRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.TenantProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import java.io.IOException;

@Service
@RequiredArgsConstructor
public class TenantProfileServiceImpl implements TenantProfileService {

    private static final String UPLOAD_DIR = "uploads/ekyc/";

    private final TenantProfileRepository tenantProfileRepository;
    private final UserRepository userRepository;

    @Override
    public TenantProfile getProfileByUserId(Long userId) {
        return tenantProfileRepository.findByUserId(userId)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new RuntimeException("User not found"));
                    TenantProfile newProfile = new TenantProfile();
                    newProfile.setUser(user);
                    newProfile.setTrustScore(100);
                    newProfile.setKycStatus(KycStatus.UNVERIFIED);
                    return tenantProfileRepository.save(newProfile);
                });
    }

    @Override
    @Transactional
    public TenantProfile verifyEkyc(Long userId, String cccdNumber) {
        if (tenantProfileRepository.existsByCccdNumber(cccdNumber)) {
            // Check if this user already owns it
            TenantProfile currentProfile = tenantProfileRepository.findByUserId(userId).orElse(null);
            if (currentProfile == null || !cccdNumber.equals(currentProfile.getCccdNumber())) {
                throw new IllegalArgumentException("CCCD_ALREADY_EXISTS");
            }
        }

        TenantProfile profile = getProfileByUserId(userId);
        profile.setCccdNumber(cccdNumber);
        profile.setKycStatus(KycStatus.APPROVED); // Mock behavior for legacy
        return tenantProfileRepository.save(profile);
    }

    @Override
    @Transactional
    public TenantProfile submitEkyc(Long userId, String cccdNumber, String fullName, String dateOfBirth, String gender, String hometown, String issuePlace, String issueDate, String features, MultipartFile cccdFront, MultipartFile cccdBack, MultipartFile selfie) {
        if (tenantProfileRepository.existsByCccdNumber(cccdNumber)) {
            TenantProfile currentProfile = tenantProfileRepository.findByUserId(userId).orElse(null);
            if (currentProfile == null || !cccdNumber.equals(currentProfile.getCccdNumber())) {
                throw new IllegalArgumentException("CCCD_ALREADY_EXISTS");
            }
        }

        TenantProfile profile = getProfileByUserId(userId);
        profile.setCccdNumber(cccdNumber);
        
        // Parse and set dates if provided (ISO 8601 format e.g., 2000-01-01T00:00:00.000Z)
        try {
            if (dateOfBirth != null && !dateOfBirth.trim().isEmpty()) {
                profile.setDateOfBirth(java.time.ZonedDateTime.parse(dateOfBirth).toLocalDateTime());
            }
            if (issueDate != null && !issueDate.trim().isEmpty()) {
                profile.setCccdIssueDate(java.time.ZonedDateTime.parse(issueDate).toLocalDateTime());
            }
        } catch (Exception e) {
            System.err.println("Error parsing eKYC dates: " + e.getMessage());
        }

        // Set other text fields
        if (gender != null) profile.setGender(gender);
        if (hometown != null) profile.setHometown(hometown);
        if (issuePlace != null) profile.setCccdIssuePlace(issuePlace);

        // Update User's full name
        User user = profile.getUser();
        if (fullName != null && !fullName.trim().isEmpty()) {
            user.setName(fullName);
            userRepository.save(user);
        }

        if (cccdFront != null) profile.setCccdFrontUrl(saveFile(cccdFront, "front"));
        if (cccdBack != null) profile.setCccdBackUrl(saveFile(cccdBack, "back"));
        if (selfie != null) profile.setSelfieUrl(saveFile(selfie, "selfie"));
        
        profile.setKycStatus(KycStatus.APPROVED);
        return tenantProfileRepository.save(profile);
    }

    @Override
    @Transactional
    public void requestReverify(Long userId) {
        TenantProfile profile = getProfileByUserId(userId);
        if (profile.getKycStatus() == KycStatus.APPROVED) {
            profile.setKycStatus(KycStatus.REVERIFY_REQUESTED);
            tenantProfileRepository.save(profile);
        } else {
            throw new RuntimeException("Chỉ có thể yêu cầu xác thực lại khi trạng thái đã được phê duyệt.");
        }
    }

    private String saveFile(MultipartFile file, String prefix) {
        if (file == null || file.isEmpty()) return null;
        try {
            Files.createDirectories(Paths.get(UPLOAD_DIR));
            String filename = prefix + "_" + UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path dest = Paths.get(UPLOAD_DIR + filename);
            Files.write(dest, file.getBytes());
            return "/uploads/ekyc/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Lỗi upload file: " + e.getMessage());
        }
    }
}
