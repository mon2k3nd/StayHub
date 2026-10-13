package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "kyc_requests")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class KycRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "branch_name", nullable = false)
    private String branchName;

    @Column(name = "business_address", nullable = false)
    private String businessAddress;

    @Column(name = "cccd_front_url")
    private String cccdFrontUrl;

    @Column(name = "cccd_back_url")
    private String cccdBackUrl;

    @Column(name = "business_license_url")
    private String businessLicenseUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private KycStatus status = KycStatus.PENDING;

    @Column(name = "admin_note", columnDefinition = "TEXT")
    private String adminNote;

    @Column(name = "reviewed_by")
    private Long reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
