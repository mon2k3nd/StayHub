package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "cash_sessions")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CashSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // A UUID string to embed in the QR code
    @Column(name = "session_id", nullable = false, unique = true)
    private String sessionId;

    @Column(name = "creator_user_id", nullable = false)
    private Long creatorUserId; // The person who generated the QR (Owner or Staff)

    @Column(name = "scanner_user_id")
    private Long scannerUserId; // The person who scans the QR (Staff or Tenant)

    // Purpose of this QR code. E.g., "TENANT_PAY_BILL", "STAFF_HANDOVER_CASH"
    @Column(name = "session_type", nullable = false)
    private String sessionType;

    // PENDING, COMPLETED, EXPIRED, CANCELLED
    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "amount")
    private Double amount;

    @Column(name = "branch_id")
    private Long branchId;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "cash_session_items", joinColumns = @JoinColumn(name = "session_id"))
    @Column(name = "item_id")
    @Builder.Default
    private java.util.List<Long> itemIds = new java.util.ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @PrePersist
    public void generateSessionId() {
        if (this.sessionId == null) {
            this.sessionId = UUID.randomUUID().toString();
        }
    }
}
