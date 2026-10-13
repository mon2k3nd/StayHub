package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "room_inspections")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomInspection {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "staff_id", nullable = false)
    private Long staffId;

    // MOVE_IN, MOVE_OUT, PERIODIC
    @Column(name = "inspection_type", nullable = false)
    private String type;

    // DRAFT, COMPLETED
    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "DRAFT";

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "tenant_signature_url")
    private String tenantSignatureUrl;

    @Column(name = "staff_signature_url")
    private String staffSignatureUrl;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Transient
    private List<InspectionItem> items;
}
