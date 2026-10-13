package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "branch_meters")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchMeter {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private Long branchId;

    @Column(name = "month", nullable = false)
    private int month;

    @Column(name = "year", nullable = false)
    private int year;

    @Column(name = "electric_master_current")
    private Double electricMasterCurrent;

    @Column(name = "electric_master_previous")
    private Double electricMasterPrevious;

    @Column(name = "water_master_current")
    private Double waterMasterCurrent;

    @Column(name = "water_master_previous")
    private Double waterMasterPrevious;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();
}
