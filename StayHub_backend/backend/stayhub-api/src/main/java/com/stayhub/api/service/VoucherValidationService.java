package com.stayhub.api.service;

import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Voucher;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.VoucherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class VoucherValidationService {

    private final VoucherRepository voucherRepository;
    private final UserRepository userRepository;

    /**
     * Tích hợp Pessimistic Locking và Fraud Detection khi người dùng chốt Hợp đồng
     */
    @Transactional
    public Voucher validateAndLockVoucher(Long voucherId, Long tenantId, Long landlordId, Long roomId, Long branchId) {
        // 1. Pessimistic Lock trên Database để chống Race Condition (Spam Click)
        Voucher voucher = voucherRepository.findByIdWithPessimisticLock(voucherId)
                .orElseThrow(() -> new RuntimeException("Voucher not found"));

        if (!voucher.isValidForNewUse()) {
            throw new RuntimeException("Voucher is exhausted, inactive, or expired");
        }

        // 2. Fraud Detection
        if (voucher.getFundedBy() == Voucher.FundedBy.ADMIN) {
            User tenant = userRepository.findById(tenantId)
                    .orElseThrow(() -> new RuntimeException("Tenant not found"));
            User landlord = userRepository.findById(landlordId)
                    .orElseThrow(() -> new RuntimeException("Landlord not found"));

            // Cross-checks for Fraud Detection
            // TODO: Bổ sung logic cross-check CCCD và Bank Account khi schema hoàn thiện cho cả 2 bên.
            // String tenantCccd = (tenant.getTenantProfile() != null) ? tenant.getTenantProfile().getCccdNumber() : null;
            // String landlordCccd = ...
            // if (tenantCccd != null && landlordCccd != null && tenantCccd.equals(landlordCccd)) {
            //     throw new RuntimeException("Fraud Detected: Sàn không áp dụng mã cho người thuê và chủ nhà có cùng CCCD");
            // }
        }

        // 3. Scope Check
        if (voucher.getScopeType() == Voucher.ScopeType.ROOM && !Boolean.TRUE.equals(voucher.getApplyAllRooms())) {
            if (voucher.getTargetIds() != null) {
                try {
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    java.util.List<String> targetIdsList = mapper.readValue(
                        voucher.getTargetIds(), 
                        new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {}
                    );
                    if (!targetIdsList.contains(String.valueOf(roomId))) {
                        throw new RuntimeException("Voucher is not applicable for this room");
                    }
                } catch (Exception e) {
                    throw new RuntimeException("Lỗi đọc danh sách phòng áp dụng mã giảm giá");
                }
            }
        } else if (voucher.getScopeType() == Voucher.ScopeType.PROPERTY && !Boolean.TRUE.equals(voucher.getApplyAllRooms())) {
            if (voucher.getBranchId() != null && !voucher.getBranchId().equals(branchId)) {
                throw new RuntimeException("Voucher is not applicable for this property");
            }
        }

        // 4. Trừ Quota (Kho)
        voucher.setUsedCount(voucher.getUsedCount() + 1);
        return voucherRepository.save(voucher);
    }
}
