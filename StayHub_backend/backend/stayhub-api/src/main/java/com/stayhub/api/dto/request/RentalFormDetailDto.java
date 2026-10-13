package com.stayhub.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentalFormDetailDto {

    @NotBlank(message = "Họ tên không được để trống")
    private String fullName;

    @NotBlank(message = "CCCD/CMND không được để trống")
    @Pattern(regexp = "^[0-9]{9,12}$", message = "CCCD/CMND không hợp lệ")
    private String idCardNumber;

    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^(0|\\+84)[0-9]{9}$", message = "Số điện thoại không hợp lệ")
    private String phoneNumber;

    @NotBlank(message = "Quê quán không được để trống")
    private String hometown;

    @NotBlank(message = "Nghề nghiệp không được để trống")
    private String occupation;

    @NotNull(message = "Số lượng người ở không được để trống")
    private Integer numberOfTenants;
}
