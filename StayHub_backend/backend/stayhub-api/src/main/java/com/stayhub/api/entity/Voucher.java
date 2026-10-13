package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "vouchers", indexes = {
    @Index(name = "idx_voucher_code", columnList = "code", unique = true),
    @Index(name = "idx_voucher_owner", columnList = "owner_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Voucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "code", nullable = false, unique = true)
    private String code;

    @Column(name = "owner_id") // có thể NULL nếu là mã ADMIN
    private Long ownerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "created_by_role", nullable = false)
    @Builder.Default
    private CreatedByRole createdByRole = CreatedByRole.LANDLORD;

    @Enumerated(EnumType.STRING)
    @Column(name = "funded_by", nullable = false)
    @Builder.Default
    private FundedBy fundedBy = FundedBy.LANDLORD;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false)
    @Builder.Default
    private ScopeType scopeType = ScopeType.ROOM;

    @Enumerated(EnumType.STRING)
    @Column(name = "applies_to_target", nullable = false)
    @Builder.Default
    private AppliesToTarget appliesToTarget = AppliesToTarget.RENT_ONLY;

    @Column(name = "target_ids", columnDefinition = "TEXT")
    private String targetIds; // JSON array of IDs (branchId, roomId, etc.)

    @Column(name = "apply_all_rooms")
    @Builder.Default
    private Boolean applyAllRooms = false;

    @Column(name = "branch_id")
    private Long branchId;

    @Enumerated(EnumType.STRING)
    @Column(name = "discount_type", nullable = false)
    private DiscountType discountType;

    @Column(name = "discount_amount")
    private Double discountAmount;

    @Column(name = "discount_percent")
    private Double discountPercent;

    @Column(name = "max_discount_amount")
    private Double maxDiscountAmount;

    @Column(name = "months_per_tenant", nullable = false)
    @Builder.Default
    private Integer monthsPerTenant = 3;

    @Column(name = "total_usage_limit")
    @Builder.Default
    private Integer totalUsageLimit = 0;

    @Column(name = "used_count", nullable = false)
    @Builder.Default
    private Integer usedCount = 0;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    public int getRemainingUsages() {
        if (totalUsageLimit == null || totalUsageLimit == 0) return Integer.MAX_VALUE;
        return Math.max(0, totalUsageLimit - (usedCount == null ? 0 : usedCount));
    }

    public boolean isValidForNewUse() {
        if (!Boolean.TRUE.equals(isActive)) return false;
        if (endDate != null && LocalDate.now().isAfter(endDate)) return false;
        if (startDate != null && LocalDate.now().isBefore(startDate)) return false;
        return getRemainingUsages() > 0;
    }

    public double computeDiscountedPrice(double originalPrice) {
        if (discountType == DiscountType.FIXED_AMOUNT && discountAmount != null) {
            return Math.max(0, originalPrice - discountAmount);
        } else if (discountType == DiscountType.PERCENTAGE && discountPercent != null) {
            double reduced = originalPrice * (discountPercent / 100.0);
            if (maxDiscountAmount != null) reduced = Math.min(reduced, maxDiscountAmount);
            return Math.max(0, originalPrice - reduced);
        }
        return originalPrice;
    }

    public enum DiscountType {
        FIXED_AMOUNT,   
        PERCENTAGE      
    }
    
    public enum CreatedByRole {
        ADMIN,
        LANDLORD
    }

    public enum FundedBy {
        ADMIN,
        LANDLORD
    }

    public enum ScopeType {
        GLOBAL,
        PROPERTY,
        ROOM,
        SERVICE
    }

    public enum AppliesToTarget {
        RENT_ONLY,
        SERVICE_ONLY,
        TOTAL_BILL
    }
}
