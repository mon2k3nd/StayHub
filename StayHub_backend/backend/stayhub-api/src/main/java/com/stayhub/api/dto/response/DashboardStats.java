package com.stayhub.api.dto.response;

import lombok.*;

import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DashboardStats {

    private long totalRooms;
    private long occupiedRooms;
    private long emptyRooms;
    private long expiringContracts;
    
    private long unpublishedRooms;
    private long maintenanceRooms;
    private long pendingConfigRooms; // Phòng auto-generated chờ chủ nhà cấu hình

    private double totalRevenueThisMonth;
    private double totalExpensesThisMonth;
    private double netProfitThisMonth;

    private long unpaidBillsCount;
    private double unpaidBillsAmount;

    private long totalTenants;
    private long totalBranches;

    // Các trường dữ liệu thật cho thẻ Profit Card
    private String currentPlanName;
    private double profitGrowthRate;
    private long paidBillsThisMonth;
    private long totalBillsThisMonth;
    private String previousMonthLabel;

    private List<MonthlyRevenue> revenueChart;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class MonthlyRevenue {
        private int month;
        private int year;
        private double revenue;
        private double expenses;
    }
}
