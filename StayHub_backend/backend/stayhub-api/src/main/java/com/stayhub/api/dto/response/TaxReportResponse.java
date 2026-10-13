package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaxReportResponse {
    private Long ownerId;
    private int year;
    private int month;
    private double totalRevenue;
    private double vatTax; // Value Added Tax (e.g. 5%)
    private double pitTax; // Personal Income Tax (e.g. 5%)
    private double totalTaxPayable;
}
