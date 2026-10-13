package com.stayhub.api.service;

import com.stayhub.api.dto.response.analytics.OwnerFinancialAnalyticsDto;
import com.stayhub.api.dto.response.analytics.OwnerOccupancyAnalyticsDto;
import com.stayhub.api.dto.response.analytics.OwnerOpsAnalyticsDto;

public interface AdvancedOwnerAnalyticsService {
    OwnerFinancialAnalyticsDto getFinancialAnalytics(String username, int months);
    OwnerOccupancyAnalyticsDto getOccupancyAnalytics(String username);
    OwnerOpsAnalyticsDto getOpsAnalytics(String username);
}
