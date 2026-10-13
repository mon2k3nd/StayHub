package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "rental_requests")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RentalRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private RequestStatus status;

    @Column(name = "submitted_at", nullable = false)
    private LocalDateTime submittedAt;

    @Column(name = "branch_id")
    private Long branchId;

    @Column(name = "move_in_date")
    private java.time.LocalDate moveInDate;

    @Column(name = "note", length = 500)
    private String note;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "form_data", columnDefinition = "jsonb")
    private java.util.Map<String, Object> formData;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "inspection_data", columnDefinition = "jsonb")
    private java.util.Map<String, Object> inspectionData;

    @Column(name = "is_escrow")
    @Builder.Default
    private Boolean isEscrow = false;
}
