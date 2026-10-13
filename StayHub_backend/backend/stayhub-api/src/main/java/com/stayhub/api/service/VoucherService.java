package com.stayhub.api.service;

import com.stayhub.api.entity.Voucher;
import com.stayhub.api.entity.VoucherRoom;
import com.stayhub.api.repository.VoucherRepository;
import com.stayhub.api.repository.VoucherRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class VoucherService {

    private final VoucherRepository voucherRepository;
    private final VoucherRoomRepository voucherRoomRepository;

    public List<Voucher> getVouchersByOwner(Long ownerId) {
        return voucherRepository.findByOwnerIdOrderByCreatedAtDesc(ownerId);
    }

    @Transactional
    public Voucher createVoucher(Long ownerId, Voucher voucher, List<Long> roomIds) {
        voucher.setOwnerId(ownerId);
        Voucher savedVoucher = voucherRepository.save(voucher);
        
        if (roomIds != null && !roomIds.isEmpty()) {
            for (Long roomId : roomIds) {
                VoucherRoom vr = VoucherRoom.builder()
                        .voucherId(savedVoucher.getId())
                        .roomId(roomId)
                        .build();
                voucherRoomRepository.save(vr);
            }
        }
        
        return savedVoucher;
    }

    public Optional<Voucher> validateVoucher(String code, Long roomId) {
        Optional<Voucher> voucherOpt = voucherRepository.findByCodeAndIsActiveTrue(code);
        if (voucherOpt.isEmpty()) {
            return Optional.empty(); // Code không tồn tại hoặc đã bị khóa
        }
        
        Voucher voucher = voucherOpt.get();
        if (!voucher.isValidForNewUse()) {
            return Optional.empty(); // Đã hết hạn hoặc hết lượt
        }
        
        // Kiểm tra xem Voucher có áp dụng cho phòng này không
        List<VoucherRoom> applicableRooms = voucherRoomRepository.findByVoucherId(voucher.getId());
        boolean isApplicable = applicableRooms.stream().anyMatch(vr -> vr.getRoomId().equals(roomId));
        
        if (!isApplicable) {
            return Optional.empty(); // Code không áp dụng cho phòng này
        }
        
        return Optional.of(voucher);
    }
}
