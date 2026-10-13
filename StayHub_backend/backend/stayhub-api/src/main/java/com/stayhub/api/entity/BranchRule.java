package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "branch_rules")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchRule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private Long branchId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "penalty_amount")
    @Builder.Default
    private Double penaltyAmount = 0.0;

    @Column(name = "applies_to", length = 20)
    @Builder.Default
    private String appliesTo = "TENANT"; // TENANT, STAFF, ALL

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
