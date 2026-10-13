package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "package_subscriptions")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PackageSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "package_type", nullable = false)
    private PlanType packageType;

    @Column(name = "amount", nullable = false)
    private Double amount;

    // Mã nội dung chuyển khoản để admin đối soát: VD "STAYHUB PRO OWNER102"
    @Column(name = "transfer_code", nullable = false, unique = true)
    private String transferCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private SubscriptionStatus status = SubscriptionStatus.PENDING;

    @Column(name = "activated_by")
    private Long activatedBy;

    @Column(name = "activated_at")
    private LocalDateTime activatedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "requested_at")
    @Builder.Default
    private LocalDateTime requestedAt = LocalDateTime.now();
}
