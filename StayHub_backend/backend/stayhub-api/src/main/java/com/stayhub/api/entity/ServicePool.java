package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "service_pools")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ServicePool {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private Long branchId;

    @Column(name = "name", nullable = false)
    private String name; 

    @Column(name = "service_type", nullable = false)
    private String serviceType; // ELECTRICITY, WATER, CLEANING, ELEVATOR, WIFI, OTHER

    @Column(name = "allocation_method", nullable = false)
    private String allocationMethod; // METERED, FLAT_PER_ROOM, FLAT_PER_TENANT, SHARED_EQUAL_ROOM, SHARED_EQUAL_HEAD, SHARED_RATIO

    @Column(name = "price")
    private Double price; 

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}