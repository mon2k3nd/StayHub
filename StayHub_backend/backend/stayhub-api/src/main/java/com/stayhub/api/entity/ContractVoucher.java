package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "contract_vouchers")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ContractVoucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @Column(name = "voucher_id", nullable = false)
    private Long voucherId;

    // Snapshot fields to ensure data immutability
    @Column(name = "snapshot_code", nullable = false)
    private String snapshotCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "snapshot_discount_type", nullable = false)
    private Voucher.DiscountType snapshotDiscountType;

    @Column(name = "snapshot_discount_amount")
    private Double snapshotDiscountAmount;

    @Column(name = "snapshot_discount_percent")
    private Double snapshotDiscountPercent;

    @Column(name = "snapshot_max_discount")
    private Double snapshotMaxDiscount;

    @Enumerated(EnumType.STRING)
    @Column(name = "snapshot_funded_by", nullable = false)
    private Voucher.FundedBy snapshotFundedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "snapshot_applies_to", nullable = false)
    private Voucher.AppliesToTarget snapshotAppliesTo;

    @Column(name = "snapshot_months_per_tenant", nullable = false)
    private Integer snapshotMonthsPerTenant;

    // Usage tracking
    @Column(name = "applied_months_count", nullable = false)
    @Builder.Default
    private Integer appliedMonthsCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private ContractVoucherStatus status = ContractVoucherStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum ContractVoucherStatus {
        ACTIVE,
        COMPLETED, // Reached snapshot_months_per_tenant
        TERMINATED // Early termination of contract
    }
}
