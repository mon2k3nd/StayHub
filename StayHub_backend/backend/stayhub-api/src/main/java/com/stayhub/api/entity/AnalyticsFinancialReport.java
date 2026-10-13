package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "analytics_financial_reports", indexes = {
    @Index(name = "idx_report_date", columnList = "report_date"),
    @Index(name = "idx_report_month_year", columnList = "report_month, report_year")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AnalyticsFinancialReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "report_date", nullable = false, unique = true)
    private LocalDate reportDate;

    @Column(name = "report_month", nullable = false)
    private Integer reportMonth;

    @Column(name = "report_year", nullable = false)
    private Integer reportYear;

    @Column(name = "total_revenue", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalRevenue = BigDecimal.ZERO;

    @Column(name = "saas_revenue", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal saasRevenue = BigDecimal.ZERO;

    @Column(name = "commission_revenue", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal commissionRevenue = BigDecimal.ZERO;

    @Column(name = "free_packages_sold")
    @Builder.Default
    private Integer freePackagesSold = 0;

    @Column(name = "basic_packages_sold")
    @Builder.Default
    private Integer basicPackagesSold = 0;

    @Column(name = "pro_packages_sold")
    @Builder.Default
    private Integer proPackagesSold = 0;

    @Column(name = "enterprise_packages_sold")
    @Builder.Default
    private Integer enterprisePackagesSold = 0;

    @Column(name = "churned_owners_count")
    @Builder.Default
    private Integer churnedOwnersCount = 0;

    @Column(name = "at_risk_owners_count")
    @Builder.Default
    private Integer atRiskOwnersCount = 0;

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
