package com.stayhub.api.service;

import com.stayhub.api.dto.response.DashboardStats;

public interface DashboardService {

    DashboardStats getOwnerStats(Long ownerId, int month, int year);
}
