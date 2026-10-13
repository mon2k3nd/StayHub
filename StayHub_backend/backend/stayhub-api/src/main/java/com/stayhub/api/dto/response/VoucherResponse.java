package com.stayhub.api.dto.response;

import com.stayhub.api.entity.Voucher;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class VoucherResponse {
    private Long id;
    private String code;
    private Voucher.DiscountType discountType;
    private Double discountAmount;
    private Double discountPercent;
    private Double maxDiscountAmount;
    private Voucher.FundedBy fundedBy;
    private Voucher.AppliesToTarget appliesToTarget;
    private Voucher.ScopeType scopeType;
    private Long branchId;
    private Boolean applyAllRooms;
    private String targetIds;
    private Integer totalUsageLimit;
    private Integer usedCount;
    private Integer monthsPerTenant;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDate endDate;
    private Voucher.CreatedByRole createdByRole;

    public static VoucherResponse fromEntity(Voucher voucher) {
        return VoucherResponse.builder()
                .id(voucher.getId())
                .code(voucher.getCode())
                .discountType(voucher.getDiscountType())
                .discountAmount(voucher.getDiscountAmount())
                .discountPercent(voucher.getDiscountPercent())
                .maxDiscountAmount(voucher.getMaxDiscountAmount())
                .fundedBy(voucher.getFundedBy())
                .appliesToTarget(voucher.getAppliesToTarget())
                .scopeType(voucher.getScopeType())
                .branchId(voucher.getBranchId())
                .applyAllRooms(voucher.getApplyAllRooms())
                .targetIds(voucher.getTargetIds())
                .totalUsageLimit(voucher.getTotalUsageLimit())
                .usedCount(voucher.getUsedCount())
                .monthsPerTenant(voucher.getMonthsPerTenant())
                .isActive(voucher.getIsActive())
                .createdAt(voucher.getCreatedAt())
                .endDate(voucher.getEndDate())
                .createdByRole(voucher.getCreatedByRole())
                .build();
    }
}
