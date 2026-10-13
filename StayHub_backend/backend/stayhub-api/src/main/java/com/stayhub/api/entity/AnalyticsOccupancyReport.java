package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "analytics_occupancy_reports", indexes = {
    @Index(name = "idx_occupancy_report_date", columnList = "report_date"),
    @Index(name = "idx_occupancy_report_month_year", columnList = "report_month, report_year")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AnalyticsOccupancyReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "report_date", nullable = false, unique = true)
    private LocalDate reportDate;

    @Column(name = "report_month", nullable = false)
    private Integer reportMonth;

    @Column(name = "report_year", nullable = false)
    private Integer reportYear;

    // Lấp đầy phòng
    @Column(name = "total_properties")
    @Builder.Default
    private Integer totalProperties = 0;

    @Column(name = "total_rooms")
    @Builder.Default
    private Integer totalRooms = 0;

    @Column(name = "occupied_rooms")
    @Builder.Default
    private Integer occupiedRooms = 0;

    @Column(name = "available_rooms")
    @Builder.Default
    private Integer availableRooms = 0;

    @Column(name = "maintenance_rooms")
    @Builder.Default
    private Integer maintenanceRooms = 0;

    @Column(name = "occupancy_rate", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal occupancyRate = BigDecimal.ZERO;

    // Phân khúc Khách thuê: Nghề nghiệp
    @Column(name = "student_tenants")
    @Builder.Default
    private Integer studentTenants = 0;

    @Column(name = "worker_tenants")
    @Builder.Default
    private Integer workerTenants = 0;

    @Column(name = "other_occupation_tenants")
    @Builder.Default
    private Integer otherOccupationTenants = 0;

    // Phân khúc Khách thuê: Độ tuổi
    @Column(name = "gen_z_tenants")
    @Builder.Default
    private Integer genZTenants = 0;

    @Column(name = "millennial_tenants")
    @Builder.Default
    private Integer millennialTenants = 0;

    @Column(name = "other_age_tenants")
    @Builder.Default
    private Integer otherAgeTenants = 0;

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

    public void setMaintenanceRooms(Integer maintenanceRooms) { this.maintenanceRooms = maintenanceRooms; }
    public Integer getMaintenanceRooms() { return this.maintenanceRooms; }

    public void setOccupancyRate(BigDecimal occupancyRate) { this.occupancyRate = occupancyRate; }
    public BigDecimal getOccupancyRate() { return this.occupancyRate; }

    public void setStudentTenants(Integer studentTenants) { this.studentTenants = studentTenants; }
    public Integer getStudentTenants() { return this.studentTenants; }

    public void setWorkerTenants(Integer workerTenants) { this.workerTenants = workerTenants; }
    public Integer getWorkerTenants() { return this.workerTenants; }

    public void setOtherOccupationTenants(Integer otherOccupationTenants) { this.otherOccupationTenants = otherOccupationTenants; }
    public Integer getOtherOccupationTenants() { return this.otherOccupationTenants; }

    public void setGenZTenants(Integer genZTenants) { this.genZTenants = genZTenants; }
    public Integer getGenZTenants() { return this.genZTenants; }

    public void setMillennialTenants(Integer millennialTenants) { this.millennialTenants = millennialTenants; }
    public Integer getMillennialTenants() { return this.millennialTenants; }

    public void setOtherAgeTenants(Integer otherAgeTenants) { this.otherAgeTenants = otherAgeTenants; }
    public Integer getOtherAgeTenants() { return this.otherAgeTenants; }

    public void setLastRunAt(LocalDateTime lastRunAt) { this.lastRunAt = lastRunAt; }
    public LocalDateTime getLastRunAt() { return this.lastRunAt; }

    public void setIsFinalized(Boolean isFinalized) { this.isFinalized = isFinalized; }
    public Boolean getIsFinalized() { return this.isFinalized; }

    public Integer getTotalRooms() { return this.totalRooms; }
    public Integer getAvailableRooms() { return this.availableRooms; }
    public LocalDate getReportDate() { return this.reportDate; }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
