package com.stayhub.api.service;

import com.stayhub.api.entity.TenantProfile;
import com.stayhub.api.entity.KycStatus;

import org.springframework.web.multipart.MultipartFile;

public interface TenantProfileService {
    TenantProfile getProfileByUserId(Long userId);
    TenantProfile verifyEkyc(Long userId, String cccdNumber);
    TenantProfile submitEkyc(Long userId, String cccdNumber, String fullName, String dateOfBirth, String gender, String hometown, String issuePlace, String issueDate, String features, MultipartFile cccdFront, MultipartFile cccdBack, MultipartFile selfie);
    void requestReverify(Long userId);
}
