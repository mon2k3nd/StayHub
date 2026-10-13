package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "utility_configs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UtilityConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "branch_id", nullable = false)
    private Long branchId;
    @Column(name = "allocation_method", nullable = false)
    private String allocationMethod; 
    @Column(name = "electricity_ratio")
    private Double electricityRatio;
    @Column(name = "water_ratio")
    private Double waterRatio;
    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();
}