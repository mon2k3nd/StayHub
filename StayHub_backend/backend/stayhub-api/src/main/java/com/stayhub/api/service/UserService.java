package com.stayhub.api.service;

import com.stayhub.api.dto.request.LoginRequest;
import com.stayhub.api.dto.request.RegisterRequest;
import com.stayhub.api.dto.response.LoginResponse;
import com.stayhub.api.dto.response.UserProfileResponse;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.SignatureHistory;
import com.stayhub.api.dto.request.UpdateSignatureRequest;

import java.util.List;
import java.util.Map;
import org.springframework.web.multipart.MultipartFile;

public interface UserService {
    LoginResponse register(RegisterRequest request);
    LoginResponse login(LoginRequest request);
    User getById(Long id);
    UserProfileResponse getProfileById(Long id);
    UserProfileResponse updateProfile(Long userId, Map<String, String> fields);
    void changePassword(Long userId, String oldPassword, String newPassword);
    User updateFcmToken(Long userId, String fcmToken);
    void lockAccount(Long userId);
    void unlockAccount(Long userId);
    UserProfileResponse registerAsOwner(Long userId, Map<String, String> request);
    UserProfileResponse uploadAvatar(Long userId, MultipartFile file);

    UserProfileResponse updateSignature(Long userId, UpdateSignatureRequest request);

    List<SignatureHistory> getSignatureHistory(Long userId);
}
