package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "system_legal_blueprints")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SystemLegalBlueprint {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "core_contract", nullable = false, columnDefinition = "TEXT")
    private String coreContract;

    @Column(name = "safety_clauses", columnDefinition = "TEXT")
    private String safetyClauses;

    @Column(nullable = false)
    private String status;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
