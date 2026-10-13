package com.stayhub.api.dto.request;
import lombok.Data;
@Data
public class CashConfirmRequest {
    private Double amount;
    private String notes;
}