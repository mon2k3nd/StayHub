package com.stayhub.api.dto.request;
import lombok.Data;
@Data
public class CashPaymentRequest {
    private Double amountPaid;
    private String notes;
    private String sessionId;
}