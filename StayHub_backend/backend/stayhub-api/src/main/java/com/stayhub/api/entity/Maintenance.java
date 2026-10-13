package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "maintenances")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Maintenance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "assigned_staff_id")
    private Long assignedStaffId;

    /** Phạm vi ảnh hưởng - nếu sự cố liên quan đến một Pool (VD: thang máy, nước tổng) */
    @Column(name = "pool_id")
    private Long poolId;

    /** Nếu sự cố xảy ra ở khu vực chung (VD: WC) */
    @Column(name = "shared_facility_id")
    private Long sharedFacilityId;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "proof_image_url")
    private String proofImageUrl;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "NEW"; // NEW, ASSIGNED, COMPLETED, CLOSED

    @Column(name = "material_cost")
    @Builder.Default
    private Double materialCost = 0.0;

    @Column(name = "staff_bonus")
    @Builder.Default
    private Double staffBonus = 0.0;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Transient
    private String tenantName;

    @Transient
    private String tenantPhone;

    @Transient
    private String roomName;

    @Transient
    private String branchName;

    @Column(name = "severity")
    @Builder.Default
    private String severity = "MEDIUM"; // LOW, MEDIUM, HIGH, CRITICAL

    @Column(name = "tenant_desire", columnDefinition = "TEXT")
    private String tenantDesire;

    @Column(name = "is_successful")
    private Boolean isSuccessful;

    @Column(name = "repair_details", columnDefinition = "TEXT")
    private String repairDetails;

    @Transient
    private String propertyAddress;

    @Transient
    private Double roomPrice;

    @Transient
    private Double roomArea;

    @Transient
    private java.util.List<String> roommatesPhones;
}
