package com.stayhub.api.scheduler;

import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Scheduled job kiểm tra hợp đồng ACTIVE đã quá hạn (endDate < today)
 * → Chuyển trạng thái hợp đồng sang EXPIRED
 * → Reset phòng về TRONG và xóa currentTenantId
 * 
 * Chạy mỗi giờ để đảm bảo dữ liệu luôn chính xác.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ContractExpiryScheduler {

    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;

    @Scheduled(cron = "0 0 * * * *") // Mỗi giờ
    @Transactional
    public void expireOverdueContracts() {
        log.info("[CRON] Bắt đầu kiểm tra hợp đồng hết hạn...");

        LocalDate today = LocalDate.now();
        List<Contract> activeContracts = contractRepository.findByStatus(ContractStatus.ACTIVE);

        int expiredCount = 0;

        for (Contract contract : activeContracts) {
            if (contract.getEndDate() != null && contract.getEndDate().isBefore(today)) {
                // 1. Đánh dấu hợp đồng là EXPIRED
                contract.setStatus(ContractStatus.EXPIRED);
                contract.setTerminatedAt(LocalDateTime.now());
                contract.setTerminationReason("Tự động hết hạn bởi hệ thống");
                contract.setUpdatedAt(LocalDateTime.now());
                contractRepository.save(contract);

                // 2. Reset phòng về trạng thái trống
                Optional<Room> roomOpt = roomRepository.findById(contract.getRoomId());
                if (roomOpt.isPresent()) {
                    Room room = roomOpt.get();
                    room.setStatus(RoomStatus.TRONG);
                    room.setCurrentTenantId(null);
                    roomRepository.save(room);
                    log.info("[CRON] Phòng ID={} đã được reset về TRONG (Hợp đồng #{} hết hạn)", room.getId(), contract.getId());
                }

                expiredCount++;
            }
        }

        log.info("[CRON] Hoàn tất. Đã expire {} hợp đồng.", expiredCount);
    }
}
