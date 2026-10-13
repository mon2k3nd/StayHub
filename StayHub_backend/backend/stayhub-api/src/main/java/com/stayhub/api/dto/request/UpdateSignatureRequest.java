package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class UpdateSignatureRequest {
    private String signature;
    private String otp; // Có thể null trong trường hợp lưu lần đầu
}
