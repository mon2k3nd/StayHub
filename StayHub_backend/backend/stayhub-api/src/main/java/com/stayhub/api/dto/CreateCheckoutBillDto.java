package com.stayhub.api.dto;

import lombok.Data;

@Data
public class CreateCheckoutBillDto {
    private Double rentAmount;
    private Double electricAmount;
    private Double waterAmount;
    private Double serviceAmount;
    private Double damageFee;
    private String damageReason;
    private Double electricCurrent;
    private Double waterCurrent;
}
