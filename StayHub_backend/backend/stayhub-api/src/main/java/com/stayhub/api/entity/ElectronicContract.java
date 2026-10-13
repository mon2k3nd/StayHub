package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "electronic_contracts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ElectronicContract {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "rental_request_id", nullable = false)
    private Long rentalRequestId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ElectronicContractStatus status;

    @Column(name = "raw_pdf_url", length = 500)
    private String rawPdfUrl;

    @Column(name = "ai_appendix_clauses", columnDefinition = "TEXT")
    private String aiAppendixClauses;

    @Column(name = "tenant_signature_otp", length = 6)
    private String tenantSignatureOtp;

    @Column(name = "owner_signature_otp", length = 6)
    private String ownerSignatureOtp;

    @Column(name = "paper_contract_images", columnDefinition = "TEXT")
    private String paperContractImages;

    @Column(name = "signed_at")
    private LocalDateTime signedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = ElectronicContractStatus.PENDING_AI;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
