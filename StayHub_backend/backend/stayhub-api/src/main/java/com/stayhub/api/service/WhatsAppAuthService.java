package com.stayhub.api.service;

import com.stayhub.api.dto.response.AuthResponse;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.config.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class WhatsAppAuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    public AuthResponse loginWithWhatsApp(String phoneToken) {
        String verifiedPhone = phoneToken.startsWith("+") ? phoneToken : "+84" + phoneToken;

        Optional<User> userOpt = userRepository.findByPhoneNumber(verifiedPhone);

        User user;
        if (userOpt.isPresent()) {
            user = userOpt.get();
        } else {
            user = new User();
            user.setPhoneNumber(verifiedPhone);
            user.setName("WhatsApp User");
            user.setRoleId("TENANT");
            user.setStatus(User.UserStatus.ACTIVE);
            
            user.setEmail(verifiedPhone.replace("+", "") + "@whatsapp.stayhub.local");
            user.setPasswordHash("WHATSAPP_AUTH_NO_PASSWORD");

            userRepository.save(user);
        }

        String systemAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getRoleId(), "FREE");
        String refreshTokenString = jwtUtil.generateRefreshToken(user.getId(), user.getRoleId(), "FREE");

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
                        .build())
                .build();
    }
}
