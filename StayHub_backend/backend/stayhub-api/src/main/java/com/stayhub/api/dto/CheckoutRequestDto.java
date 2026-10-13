package com.stayhub.api.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class CheckoutRequestDto {
    private Long contractId;
    private Long tenantId;
    private LocalDate targetCheckoutDate;
    private String checkoutImages;
    private String tenantNote;
}
