package com.stayhub.api.service;

import com.stayhub.api.dto.request.VoucherCreateRequest;
import com.stayhub.api.dto.response.VoucherResponse;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Voucher;
import com.stayhub.api.exception.BadRequestException;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.VoucherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VoucherManagementService {

    private final VoucherRepository voucherRepository;
    private final UserRepository userRepository;

    @Transactional
    public VoucherResponse createVoucher(Long ownerId, VoucherCreateRequest request, Voucher.CreatedByRole role, Voucher.FundedBy fundedBy) {
        // Validate Code Uniqueness
        String code = request.getCode().trim().toUpperCase();
        voucherRepository.findByCodeAndIsActiveTrue(code).ifPresent(v -> {
            throw new BadRequestException("Mã giảm giá này đã tồn tại, vui lòng chọn mã khác");
        });

        Voucher voucher = Voucher.builder()
                .code(code)
                .ownerId(ownerId)
                .discountType(request.getDiscountType())
                .discountAmount(request.getDiscountAmount())
                .discountPercent(request.getDiscountPercent())
                .maxDiscountAmount(request.getMaxDiscountAmount())
                .fundedBy(fundedBy)
                .appliesToTarget(request.getAppliesToTarget())
                .scopeType(request.getScopeType())
                .branchId(request.getBranchId())
                .applyAllRooms(request.getApplyAllRooms())
                .targetIds(request.getTargetIds())
                .totalUsageLimit(request.getTotalUsageLimit())
                .usedCount(0)
                .monthsPerTenant(request.getMonthsPerTenant())
                .isActive(true)
                .createdByRole(role)
                .createdAt(LocalDateTime.now())
                .build();

        Voucher saved = voucherRepository.save(voucher);
        return VoucherResponse.fromEntity(saved);
    }

    public Page<VoucherResponse> getAllAdminVouchers(Pageable pageable) {
        return voucherRepository.findAll(pageable).map(VoucherResponse::fromEntity);
    }

    @Transactional
    public void toggleVoucherStatus(Long voucherId, boolean isActive) {
        Voucher voucher = voucherRepository.findById(voucherId)
                .orElseThrow(() -> new ResourceNotFoundException("Voucher not found"));
        voucher.setIsActive(isActive);
        voucherRepository.save(voucher);
    }

    public List<VoucherResponse> getLandlordVouchers(Long landlordId) {
        return voucherRepository.findByOwnerIdOrderByCreatedAtDesc(landlordId).stream()
                .map(VoucherResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteLandlordVoucher(Long landlordId, Long voucherId) {
        Voucher voucher = voucherRepository.findById(voucherId)
                .orElseThrow(() -> new ResourceNotFoundException("Voucher not found"));
        
        if (!voucher.getOwnerId().equals(landlordId)) {
            throw new BadRequestException("Không có quyền xóa mã này");
        }

        // Soft delete
        voucher.setIsActive(false);
        voucherRepository.save(voucher);
    }

    public List<VoucherResponse> getActiveVouchersForRoom(Long roomId, Long landlordId) {
        // Lấy mã của Sàn (Admin) và mã của Chủ nhà
        // Đơn giản hóa: Lấy tất cả mã active (Sẽ filter chi tiết bằng logic RoomScope nếu cần)
        List<Voucher> activeVouchers = voucherRepository.findByIsActiveTrue();
        
        // Filter logic có thể implement chi tiết ở đây (vd: check targetIds)
        return activeVouchers.stream()
                .filter(v -> v.getFundedBy() == Voucher.FundedBy.ADMIN || v.getOwnerId().equals(landlordId))
                .filter(v -> v.getUsedCount() < v.getTotalUsageLimit())
                .map(VoucherResponse::fromEntity)
                .collect(Collectors.toList());
    }
}
