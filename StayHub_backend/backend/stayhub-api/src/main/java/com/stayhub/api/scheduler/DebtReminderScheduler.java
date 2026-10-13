package com.stayhub.api.scheduler;

import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Room;
import com.stayhub.api.service.notification.SmsZaloProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DebtReminderScheduler {

    private final BillRepository billRepository;
    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final RoomRepository roomRepository;
    private final SmsZaloProvider smsZaloProvider;

    /**
     * Chạy vào lúc 08:00 sáng ngày mùng 5 hàng tháng.
     * Quét tất cả các hóa đơn trạng thái PENDING.
     */
    @Scheduled(cron = "0 0 8 5 * ?")
    @Transactional(readOnly = true)
    public void scheduleDebtReminder() {
        log.info(">>>> Bắt đầu tiến trình tự động nhắc nợ vào mùng 5 hàng tháng <<<<");

        // Lấy tất cả hóa đơn đang PENDING
        List<Bill> unpaidBills = billRepository.findByStatus("PENDING");

        for (Bill bill : unpaidBills) {
            try {
                processReminder(bill);
            } catch (Exception e) {
                log.error("Lỗi khi gửi nhắc nợ cho hóa đơn ID {}: {}", bill.getId(), e.getMessage());
            }
        }

        log.info(">>>> Hoàn tất tiến trình nhắc nợ tự động <<<<");
    }

    private void processReminder(Bill bill) {
        if (bill.getContractId() == null || bill.getTenantId() == null || bill.getRoomId() == null) {
            return;
        }

        User tenant = userRepository.findById(bill.getTenantId()).orElse(null);
        Room room = roomRepository.findById(bill.getRoomId()).orElse(null);

        if (tenant == null || room == null) {
            return;
        }

        String tenantPhone = tenant.getPhoneNumber();
        String tenantName = tenant.getName();
        String roomName = room.getRoomName();

        if (tenantPhone == null || tenantPhone.isEmpty()) {
            return;
        }

        String message = String.format("StayHub thông báo: Chào %s, hóa đơn phòng %s tháng %d/%d của bạn (Tổng: %,.0f VND) vẫn chưa được thanh toán. Vui lòng thanh toán sớm để tránh bị gián đoạn dịch vụ. Trân trọng!", 
            tenantName, roomName, bill.getMonth(), bill.getYear(), bill.getTotalAmount());

        // Gửi SMS
        smsZaloProvider.sendSms(tenantPhone, message);
        
        // Gửi Zalo (Mock)
        smsZaloProvider.sendZaloMessage(tenantPhone, message);
    }
}
