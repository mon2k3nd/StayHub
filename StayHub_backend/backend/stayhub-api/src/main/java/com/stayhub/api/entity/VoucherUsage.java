package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "voucher_usages", indexes = {
    @Index(name = "idx_usage_voucher", columnList = "voucher_id"),
    @Index(name = "idx_usage_tenant", columnList = "tenant_id"),
    @Index(name = "idx_usage_contract", columnList = "contract_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VoucherUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "voucher_id", nullable = false)
    private Long voucherId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @Column(name = "used_at", nullable = false)
    @Builder.Default
    private LocalDateTime usedAt = LocalDateTime.now();
}
