package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "checkout_requests")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CheckoutRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "PENDING"; // PENDING, APPROVED, REJECTED, PAYMENT_PENDING, DISPUTED, COMPLETED

    @Column(name = "target_checkout_date", nullable = false)
    private LocalDate targetCheckoutDate;

    @Column(name = "checkout_images", columnDefinition = "TEXT")
    private String checkoutImages;

    @Column(name = "tenant_note", columnDefinition = "TEXT", nullable = false)
    private String tenantNote;

    @Column(name = "owner_reason", columnDefinition = "TEXT")
    private String ownerReason;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();
}
