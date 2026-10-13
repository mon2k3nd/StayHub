package com.stayhub.api.dto.response.analytics;

import com.stayhub.api.dto.response.ChartDataDto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class OwnerFinancialAnalyticsDto {
    private Double gmv; // Gross Merchandise Value
    private Double netIncome;
    private Double totalExpense;
    private Double badDebt; // Nợ đọng
    private Double onTimePaymentRate; // %
    private Double ownerNetProfitMargin; // %
    
    // Charts
    private List<ChartDataDto> revenueBreakdown; // Tiền phòng vs Tiền điện vs Nước
    private List<ChartDataDto> cashflowTrend; // Lịch sử dòng tiền 12 tháng
    private List<ChartDataDto> expenseBreakdown;
}
