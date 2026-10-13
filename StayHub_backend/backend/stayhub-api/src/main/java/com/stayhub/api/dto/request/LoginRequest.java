package com.stayhub.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {

    @NotBlank(message = "Email hoặc SĐT không được để trống")
    private String emailOrPhone;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}
