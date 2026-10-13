package com.stayhub.api.dto.response.analytics;

import com.stayhub.api.dto.response.ChartDataDto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class OwnerOccupancyAnalyticsDto {
    private Integer totalBranches;
    private Integer totalRooms;
    private Integer activeTenants;
    private Double realTimeOccupancyRate; // %
    private Integer totalAssetsValue; 
    
    // Charts
    private List<ChartDataDto> occupancyByBranch;
    private List<ChartDataDto> churnReasons; // Phân tích lý do dời đi
    private List<ChartDataDto> roomStatusDistribution; // Trống, Đang ở, Bảo trì
}
