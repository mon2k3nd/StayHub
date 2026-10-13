package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "violation_reports")
@org.hibernate.annotations.SQLDelete(sql = "UPDATE violation_reports SET is_deleted = true WHERE id=?")
@org.hibernate.annotations.Where(clause = "is_deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ViolationReport {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "rule_id")
    private Long ruleId;

    @Column(name = "reporter_id")
    private Long reporterId;

    @Column(name = "target_type", length = 20)
    @Builder.Default
    private String targetType = "TENANT"; // TENANT or STAFF

    @Column(name = "target_id")
    private Long targetId; // room_id if TENANT, staff_id if STAFF

    @Column(name = "room_id")
    private Long roomId;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "violation_type")
    private String violationType;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "penalty_amount")
    private Double penaltyAmount;

    @Column(name = "status")
    @Builder.Default
    private String status = "PENDING"; 
    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;
}