package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "saas_plans")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SaasPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "plan_type", unique = true, nullable = false)
    private String planType; // FREE, PRO, ENTERPRISE

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "price", nullable = false)
    private Double price;

    @Column(name = "max_rooms")
    private Integer maxRooms;

    @Column(name = "max_branches")
    private Integer maxBranches;

    @Column(name = "max_staffs")
    private Integer maxStaffs;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;
}
