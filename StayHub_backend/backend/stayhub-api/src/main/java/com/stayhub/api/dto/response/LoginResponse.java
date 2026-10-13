package com.stayhub.api.dto.response;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LoginResponse {
    private String accessToken;
    private Long userId;
    private String name;
    private String phoneNumber;
    private String roleId;
    private String packageId;
    private String accountStatus;
    private String avatarUrl;
}
