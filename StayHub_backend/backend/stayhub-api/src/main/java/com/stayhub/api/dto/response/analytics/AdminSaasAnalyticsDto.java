package com.stayhub.api.dto.response.analytics;

import com.stayhub.api.dto.response.ChartDataDto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class AdminSaasAnalyticsDto {
    private Double mrr; // Monthly Recurring Revenue
    private Double arr; // Annual Recurring Revenue
    private Double ltv; // Lifetime Value
    private Double cac; // Customer Acquisition Cost
    private Double churnRate; // %
    
    // Charts
    private List<ChartDataDto> planDistribution;
    private List<ChartDataDto> mrrGrowthTrend; // 12 months MRR
    private List<ChartDataDto> revenueByPaymentMethod; // VNPay vs Stripe vs Cash
}
