package com.stayhub.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PhoneVerifyRequest {

    @NotBlank(message = "Số điện thoại không được để trống")
    private String phoneNumber;

    @NotBlank(message = "Firebase UID không được để trống")
    private String firebaseUid;
}
