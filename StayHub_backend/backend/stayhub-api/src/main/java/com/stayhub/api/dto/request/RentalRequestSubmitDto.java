package com.stayhub.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentalRequestSubmitDto {

    @NotBlank(message = "Session token không được để trống")
    private String sessionToken;

    private Long tenantId; // Added for Backend fix

    @NotNull(message = "Room ID không được để trống")
    private Long roomId;

    private Long branchId;
    
    @NotNull(message = "Ngày chuyển vào không được để trống")
    private LocalDate moveInDate;
    
    private String note;
    
    // activeOtpCode is deprecated as we use sessionToken now
    // private String activeOtpCode;

    @NotNull(message = "Dữ liệu form không được để trống")
    @Valid
    private RentalFormDetailDto formData;
}
