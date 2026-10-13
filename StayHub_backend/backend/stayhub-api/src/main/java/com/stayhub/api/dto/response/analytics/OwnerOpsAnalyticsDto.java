package com.stayhub.api.dto.response.analytics;

import com.stayhub.api.dto.response.ChartDataDto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class OwnerOpsAnalyticsDto {
    private Integer totalTickets;
    private Integer openTickets;
    private Double avgResolutionTimeHours; // MTTR
    private Double maintenanceCsat; // 0-5
    
    // Contracts & Compliance
    private Double leadToLeaseConversion; // %
    private Double eSignatureAdoption; // %
    private Double tenantRetentionRate; // %
    private Integer totalDisputes;
    
    // Charts
    private List<ChartDataDto> ticketStatusDistribution;
    private List<ChartDataDto> staffWorkload;
}
