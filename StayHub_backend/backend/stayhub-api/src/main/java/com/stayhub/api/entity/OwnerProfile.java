package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "owner_profiles")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OwnerProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private User user;

    @Column(name = "bank_name")
    private String bankName;

    @Column(name = "bank_account_number")
    private String bankAccountNumber;

    @Column(name = "bank_account_name")
    private String bankAccountName;

    @Column(name = "signature", columnDefinition = "TEXT")
    private String signature;

    @Column(name = "contract_template", columnDefinition = "TEXT")
    private String contractTemplate;

    @Enumerated(EnumType.STRING)
    @Column(name = "owner_status")
    @Builder.Default
    private OwnerStatus ownerStatus = OwnerStatus.PENDING_VERIFICATION;

    @Column(name = "package_id")
    private String packageId;

    @Column(name = "expired_at")
    private LocalDateTime expiredAt;

    @Column(name = "is_requesting_owner")
    @Builder.Default
    private Boolean requestingOwner = false;

    @Column(name = "is_super_landlord")
    @Builder.Default
    private Boolean isSuperLandlord = false;


    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
