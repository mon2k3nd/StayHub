package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private String token;
    private String refreshToken;
    private UserPayload user;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserPayload {
        private Long id;
        /**
         * FIX: dùng String roleId (e.g. "OWNER", "TENANT", "STAFF")
         * để Flutter AuthProvider._saveFromResponse() đọc user['roleId'] đúng
         */
        private String roleId;
        /**
         * FIX: dùng String packageId (e.g. "FREE", "BASIC", "PRO")
         * để Flutter AuthProvider._saveFromResponse() đọc user['packageId'] đúng
         */
        private String packageId;
        private String fullName;
        private String email;
        private String phone;
        private String avatarUrl;
        private String status;
        private String ownerStatus;
        private Boolean requirePasswordSetup;
    }

    public static AuthResponse of(String token, Long id, String role,
                                   String plan, String fullName,
                                   String email, String phone) {
        return AuthResponse.builder()
                .token(token)
                .user(UserPayload.builder()
                        .id(id)
                        .roleId(role)
                        .packageId(plan)
                        .fullName(fullName)
                        .email(email)
                        .phone(phone)
                        // status and ownerStatus not needed in this legacy method but adding nulls
                        .status("ACTIVE")
                        .ownerStatus("APPROVED")
                        .build())
                .build();
    }
}
