package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.DashboardStats;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.repository.*;
import com.stayhub.api.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;
    private final BillRepository billRepository;
    private final BranchRepository branchRepository;
    private final UserRepository userRepository;
    private final ExpenseRepository expenseRepository;
    private final OwnerSubscriptionRepository ownerSubscriptionRepository;
    private final com.stayhub.api.repository.RoomPostRepository roomPostRepository;

    @Override
    public DashboardStats getOwnerStats(Long ownerId, int month, int year) {
        // Lấy các chi nhánh hợp lệ (isActive = true và COMPLETED)
        List<Long> validBranchIds = branchRepository.findByOwnerIdAndIsActiveTrue(ownerId).stream()
                .filter(b -> !"DRAFT".equalsIgnoreCase(b.getCreationStatus()) && !"INCOMPLETE".equalsIgnoreCase(b.getCreationStatus()))
                .map(com.stayhub.api.entity.Branch::getId)
                .toList();

        // Phòng đã cấu hình (bỏ qua phòng chờ setup KHOA_CHO_CAP_NHAT, phòng đã xóa DONG_CUA, và phòng thuộc chi nhánh chưa kích hoạt)
        List<com.stayhub.api.entity.Room> allRooms = roomRepository.findByOwnerId(ownerId).stream()
                .filter(r -> r.getStatus() != RoomStatus.DONG_CUA)
                .filter(r -> r.getBranchId() != null && validBranchIds.contains(r.getBranchId()))
                .toList();
                
        List<com.stayhub.api.entity.Room> configuredRooms = roomRepository.findConfiguredByOwnerId(ownerId).stream()
                .filter(r -> r.getStatus() != RoomStatus.DONG_CUA)
                .filter(r -> r.getBranchId() != null && validBranchIds.contains(r.getBranchId()))
                .toList();
        long totalRooms = configuredRooms.size();
        long pendingConfigRooms = allRooms.size() - totalRooms; // Phòng chưa cấu hình

        // Lấy danh sách hợp đồng ACTIVE của owner để cross-check (chỉ xét hợp đồng thuộc các phòng hợp lệ)
        List<Long> validRoomIds = allRooms.stream().map(com.stayhub.api.entity.Room::getId).toList();
        List<com.stayhub.api.entity.Contract> activeContracts = contractRepository.findByOwnerId(ownerId).stream()
                .filter(c -> c.getStatus() == ContractStatus.ACTIVE)
                .filter(c -> validRoomIds.contains(c.getRoomId()))
                .toList();

        // Đếm phòng thực sự đang cho thuê: số lượng phòng riêng biệt có hợp đồng ACTIVE
        long occupiedRooms = activeContracts.stream().map(c -> c.getRoomId()).distinct().count();
        
        long totalOccupied = occupiedRooms;
        // emptyRooms = chỉ tính những phòng đã cấu hình và đang trống
        long emptyRooms = configuredRooms.stream()
                .filter(r -> r.getStatus() == RoomStatus.TRONG)
                .count();

        long maintenanceRooms = configuredRooms.stream()
                .filter(r -> r.getStatus() == RoomStatus.BAO_TRI)
                .count();

        List<com.stayhub.api.entity.RoomPost> activePosts = roomPostRepository.findByOwnerId(ownerId).stream()
                .filter(p -> "ACTIVE".equals(p.getStatus()))
                .toList();

        long unpublishedRooms = configuredRooms.stream()
                .filter(r -> r.getStatus() == RoomStatus.TRONG)
                .filter(r -> activePosts.stream().noneMatch(p -> p.getRoomId().equals(r.getId())))
                .count();

        // Hợp đồng sắp hết hạn (30 ngày)
        LocalDate today = LocalDate.now();
        List<com.stayhub.api.entity.Contract> expiringContracts =
                contractRepository.findExpiringContracts(today, today.plusDays(30));
        long expiringCount = expiringContracts.stream()
                .filter(c -> allRooms.stream().anyMatch(r -> r.getId().equals(c.getRoomId())))
                .count();

        // Doanh thu & chi phí tháng này
        List<com.stayhub.api.entity.Bill> ownerBills = billRepository.findByOwnerId(ownerId);
        
        List<com.stayhub.api.entity.Bill> paidBillsThisMonth = ownerBills.stream()
                .filter(b -> b.getIsPaid() != null && b.getIsPaid())
                .filter(b -> b.getMonth() != null && b.getYear() != null && b.getMonth() == month && b.getYear() == year)
                .toList();
                
        double revenue = paidBillsThisMonth.stream()
                .mapToDouble(b -> b.getTotalAmount() != null ? b.getTotalAmount() : 0)
                .sum();

        double expenses = expenseRepository.findByOwnerIdAndMonthAndYear(ownerId, month, year)
                .stream()
                .mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0)
                .sum();

        // Doanh thu & chi phí tháng trước để tính tăng trưởng
        LocalDate prevDate = LocalDate.of(year, month, 1).minusMonths(1);
        int pMonth = prevDate.getMonthValue();
        int pYear = prevDate.getYear();

        List<com.stayhub.api.entity.Bill> prevPaidBills = ownerBills.stream()
                .filter(b -> b.getIsPaid() != null && b.getIsPaid())
                .filter(b -> b.getMonth() != null && b.getYear() != null && b.getMonth() == pMonth && b.getYear() == pYear)
                .toList();
                
        double prevRevenue = prevPaidBills.stream()
                .mapToDouble(b -> b.getTotalAmount() != null ? b.getTotalAmount() : 0)
                .sum();
                
        double prevExpenses = expenseRepository.findByOwnerIdAndMonthAndYear(ownerId, pMonth, pYear)
                .stream()
                .mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0)
                .sum();
        
        double currentNetProfit = revenue - expenses;
        double prevNetProfit = prevRevenue - prevExpenses;
        double profitGrowthRate = 0.0;
        if (prevNetProfit > 0) {
            profitGrowthRate = ((currentNetProfit - prevNetProfit) / prevNetProfit) * 100;
        } else if (prevNetProfit <= 0 && currentNetProfit > 0) {
            profitGrowthRate = 100.0;
        }

        // Tỷ lệ thu hóa đơn
        long paidBillsCount = paidBillsThisMonth.size();
        
        // Tất cả hóa đơn chưa thanh toán của owner (công nợ)
        List<com.stayhub.api.entity.Bill> allUnpaid = ownerBills.stream()
                .filter(b -> b.getIsPaid() == null || !b.getIsPaid())
                .toList();
                
        long unpaidCount = allUnpaid.size();
        double unpaidAmount = allUnpaid.stream()
                .mapToDouble(b -> b.getTotalAmount() != null ? b.getTotalAmount() : 0)
                .sum();

        // Tính số hóa đơn tổng tháng này
        long unpaidBillsThisMonth = allUnpaid.stream()
                .filter(b -> b.getDueDate() != null && b.getDueDate().getMonthValue() == month && b.getDueDate().getYear() == year)
                .count();
        long totalBillsThisMonth = paidBillsCount + unpaidBillsThisMonth;

        // Số tenant và chi nhánh
        long totalTenants = allRooms.stream()
                .filter(r -> r.getCurrentTenantId() != null)
                .count();
        long totalBranches = validBranchIds.size();

        // Lấy thông tin gói SaaS
        String currentPlanName = "Chưa đăng ký gói";
        com.stayhub.api.entity.OwnerSubscription activeSub = ownerSubscriptionRepository.findByOwnerIdAndStatus(ownerId, "ACTIVE").orElse(null);
        if (activeSub != null && activeSub.getPlan() != null) {
            currentPlanName = "Gói " + activeSub.getPlan().getName();
        }

        // Biểu đồ doanh thu 6 tháng gần nhất
        List<DashboardStats.MonthlyRevenue> chart = new ArrayList<>();
        for (int i = 5; i >= 0; i--) {
            LocalDate d = LocalDate.of(year, month, 1).minusMonths(i);
            int m = d.getMonthValue();
            int y = d.getYear();

            double monthRevenue = ownerBills.stream()
                    .filter(b -> b.getIsPaid() != null && b.getIsPaid())
                    .filter(b -> b.getMonth() != null && b.getYear() != null && b.getMonth() == m && b.getYear() == y)
                    .mapToDouble(b -> b.getTotalAmount() != null ? b.getTotalAmount() : 0)
                    .sum();

            double monthExpenses = expenseRepository.findByOwnerIdAndMonthAndYear(ownerId, m, y)
                    .stream()
                    .mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0)
                    .sum();

            chart.add(DashboardStats.MonthlyRevenue.builder()
                    .month(m).year(y)
                    .revenue(monthRevenue)
                    .expenses(monthExpenses)
                    .build());
        }

        return DashboardStats.builder()
                .totalRooms(totalRooms)
                .occupiedRooms(totalOccupied)
                .emptyRooms(emptyRooms)
                .expiringContracts(expiringCount)
                .unpublishedRooms(unpublishedRooms)
                .maintenanceRooms(maintenanceRooms)
                .pendingConfigRooms(pendingConfigRooms)
                .totalRevenueThisMonth(revenue)
                .totalExpensesThisMonth(expenses)
                .netProfitThisMonth(revenue - expenses)
                .unpaidBillsCount(unpaidCount)
                .unpaidBillsAmount(unpaidAmount)
                .totalTenants(totalTenants)
                .totalBranches(totalBranches)
                .currentPlanName(currentPlanName)
                .profitGrowthRate(Math.round(profitGrowthRate * 10.0) / 10.0)
                .paidBillsThisMonth(paidBillsCount)
                .totalBillsThisMonth(totalBillsThisMonth)
                .previousMonthLabel("so T" + pMonth)
                .revenueChart(chart)
                .build();
    }
}
