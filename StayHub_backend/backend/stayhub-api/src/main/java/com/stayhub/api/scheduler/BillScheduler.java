package com.stayhub.api.scheduler;

import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.service.BillService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class BillScheduler {

    private final ContractRepository contractRepository;
    private final BillRepository billRepository;
    private final BillService billService;

    /**
     * Chạy vào lúc 0h00 ngày 1 hàng tháng.
     * Tự động sinh Bill dự thảo (chờ chốt điện nước) cho tất cả hợp đồng ACTIVE.
     */
    @Scheduled(cron = "0 0 0 1 * ?")
    // @Transactional removed from class/method level because we want each bill to be processed independently.
    // billService.createBill() should already be transactional or we just catch the exception per bill.
    public void generateMonthlyBills() {
        log.info("[CRONJOB] Bắt đầu tự động sinh Hóa Đơn tháng...");

        List<Contract> activeContracts = contractRepository.findByStatus(ContractStatus.ACTIVE);
        int generatedCount = 0;

        LocalDate today = LocalDate.now();
        int currentMonth = today.getMonthValue();
        int currentYear = today.getYear();

        // Query once to get all rooms that already have a bill this month
        List<Long> existingBillRoomIdsList = billRepository.findRoomIdsByMonthAndYear(currentMonth, currentYear);
        java.util.Set<Long> existingBillRoomIds = new java.util.HashSet<>(existingBillRoomIdsList);

        for (Contract contract : activeContracts) {
            // Kiểm tra xem phòng này đã có hóa đơn trong tháng chưa bằng HashSet (O(1))
            if (!existingBillRoomIds.contains(contract.getRoomId())) {
                Bill draftBill = Bill.builder()
                        .roomId(contract.getRoomId())
                        .contractId(contract.getId())
                        .tenantId(contract.getTenantId())
                        .month(currentMonth)
                        .year(currentYear)
                        // Các chỉ số điện nước sẽ được Owner nhập tay sau
                        .build();

                try {
                    billService.createBill(draftBill);
                    generatedCount++;
                } catch (Exception e) {
                    log.error("[CRONJOB] Lỗi khi tạo Bill cho phòng {}: {}", contract.getRoomId(), e.getMessage());
                }
            }
        }

        log.info("[CRONJOB] Hoàn thành sinh Hóa Đơn tháng. Đã tạo {} hóa đơn mới.", generatedCount);
    }
}
