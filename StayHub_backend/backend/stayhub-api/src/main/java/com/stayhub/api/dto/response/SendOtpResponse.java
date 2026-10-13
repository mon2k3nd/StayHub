package com.stayhub.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SendOtpResponse {

    private boolean success;
    private String message;

    /**
     * FIX: Đổi từ @JsonProperty("__dev_otp") sang camelCase "devOtp"
     * để khớp với Flutter: res['devOtp']
     * Chỉ trả về trong môi trường dev/test
     */
    private String devOtp;

    public static SendOtpResponse ok(String devOtp) {
        return SendOtpResponse.builder()
                .success(true)
                .message("OTP đã được gửi thành công")
                .devOtp(devOtp)
                .build();
    }

    public static SendOtpResponse fail(String message) {
        return SendOtpResponse.builder()
                .success(false)
                .message(message)
                .build();
    }
}
