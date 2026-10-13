package com.stayhub.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CheckInRequest {

    @NotBlank(message = "Mã nhận phòng không được để trống")
    private String checkInCode;
}
