package com.stayhub.api.dto.request;

import com.stayhub.api.entity.Otp;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SendOtpRequest {

    @NotBlank(message = "Target (email hoặc SĐT) không được để trống")
    private String target;

    @NotNull(message = "Kênh gửi OTP không được để trống")
    private Otp.Channel channel;

    @NotNull(message = "Loại OTP không được để trống")
    private Otp.OtpType type;
}
