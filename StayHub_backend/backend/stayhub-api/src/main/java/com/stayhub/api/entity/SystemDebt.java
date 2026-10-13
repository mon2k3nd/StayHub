package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "system_debts")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SystemDebt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "landlord_id", nullable = false)
    private Long landlordId;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "voucher_id")
    private Long voucherId;

    @Column(name = "bill_id")
    private Long billId;

    @Column(name = "debt_amount", nullable = false)
    private Double debtAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private DebtStatus status = DebtStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "settled_at")
    private LocalDateTime settledAt;

    public enum DebtStatus {
        PENDING,  // Waiting to be settled at the end of the month
        SETTLED,  // Money has been transferred to landlord
        CANCELLED // For edge cases where contract is voided
    }
}
