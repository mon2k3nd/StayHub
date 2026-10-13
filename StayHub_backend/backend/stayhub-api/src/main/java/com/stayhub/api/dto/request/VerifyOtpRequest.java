package com.stayhub.api.dto.request;

import com.stayhub.api.entity.Otp;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyOtpRequest {

    @NotBlank(message = "Số điện thoại hoặc email không được để trống")
    private String target;

    @NotNull(message = "Kênh gửi mã (email/sms) không được để trống")
    private Otp.Channel channel;

    @NotBlank(message = "Mã OTP không được để trống")
    private String code;

    @NotNull(message = "Loại OTP không được để trống")
    private Otp.OtpType type;
}
