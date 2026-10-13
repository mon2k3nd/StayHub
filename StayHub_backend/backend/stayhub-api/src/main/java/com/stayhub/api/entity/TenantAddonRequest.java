package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tenant_addon_requests")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TenantAddonRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addon_id", nullable = false)
    private AddonService addonService;

    @Column(name = "quantity", nullable = false)
    @Builder.Default
    private Integer quantity = 1;

    // PENDING, APPROVED, REJECTED
    @Column(name = "status")
    @Builder.Default
    private String status = "PENDING"; 

    @Column(name = "status_note", columnDefinition = "TEXT")
    private String statusNote;

    @Column(name = "requested_at")
    @Builder.Default
    private LocalDateTime requestedAt = LocalDateTime.now();

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    // Gán vào Bill của tháng nào
    @Column(name = "bill_month")
    private Integer billMonth;

    @Column(name = "bill_year")
    private Integer billYear;

    // Đã được cộng vào hóa đơn chưa
    @Column(name = "is_billed")
    @Builder.Default
    private Boolean isBilled = false;
}
