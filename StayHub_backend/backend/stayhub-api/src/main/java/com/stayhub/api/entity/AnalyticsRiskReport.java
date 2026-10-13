package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "analytics_risk_reports", indexes = {
    @Index(name = "idx_risk_report_date", columnList = "report_date"),
    @Index(name = "idx_risk_report_month_year", columnList = "report_month, report_year")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AnalyticsRiskReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "report_date", nullable = false, unique = true)
    private LocalDate reportDate;

    @Column(name = "report_month", nullable = false)
    private Integer reportMonth;

    @Column(name = "report_year", nullable = false)
    private Integer reportYear;

    // Rủi ro Tài chính (Nợ xấu)
    @Column(name = "total_unpaid_bills")
    @Builder.Default
    private Integer totalUnpaidBills = 0;

    @Column(name = "total_debt_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalDebtAmount = BigDecimal.ZERO;

    // Rủi ro Vận hành
    @Column(name = "reported_incidents")
    @Builder.Default
    private Integer reportedIncidents = 0;

    @Column(name = "cancelled_contracts")
    @Builder.Default
    private Integer cancelledContracts = 0;

    // Sức khỏe eKYC
    @Column(name = "kyc_submitted")
    @Builder.Default
    private Integer kycSubmitted = 0;

    @Column(name = "kyc_approved")
    @Builder.Default
    private Integer kycApproved = 0;

    @Column(name = "kyc_rejected")
    @Builder.Default
    private Integer kycRejected = 0;

    // Metadata
    @Column(name = "is_finalized")
    @Builder.Default
    private Boolean isFinalized = false;

    @Column(name = "last_run_at")
    private LocalDateTime lastRunAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
