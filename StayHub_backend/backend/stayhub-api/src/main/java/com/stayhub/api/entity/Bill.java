package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "bills")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Bill {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "tenant_id")
    private Long tenantId;

    @Column(name = "total_amount")
    private Double totalAmount;

    @Column(name = "original_amount")
    private Double originalAmount;

    @Column(name = "discount_amount")
    private Double discountAmount;

    @Column(name = "voucher_id")
    private Long voucherId;

    @Column(name = "month", nullable = false)
    private Integer month;

    @Column(name = "year", nullable = false)
    private Integer year;

    // Chỉ số điện cuối kỳ
    @Column(name = "electric_current")
    private Double electricCurrent;

    // Chỉ số điện đầu kỳ
    @Column(name = "electric_previous")
    private Double electricPrevious;

    // Chỉ số nước cuối kỳ
    @Column(name = "water_current")
    private Double waterCurrent;

    // Chỉ số nước đầu kỳ
    @Column(name = "water_previous")
    private Double waterPrevious;

    /** Đơn giá điện (kWh) — lấy từ hợp đồng */
    @Column(name = "electric_unit_price")
    private Double electricUnitPrice;

    /** Đơn giá nước (m3) — lấy từ hợp đồng */
    @Column(name = "water_unit_price")
    private Double waterUnitPrice;

    @Column(name = "electric_amount")
    private Double electricAmount;

    @Column(name = "water_amount")
    private Double waterAmount;

    @Column(name = "rent_amount")
    private Double rentAmount;

    @Column(name = "service_amount")
    private Double serviceAmount;


    @Column(name = "electric_image")
    private String electricImage;

    @Column(name = "water_image")
    private String waterImage;

    // VietQR payment URL
    @Column(name = "payment_qr_url", columnDefinition = "TEXT")
    private String paymentQrUrl;

    @Column(name = "is_prorated")
    @Builder.Default
    private Boolean isProrated = false;

    @Column(name = "prorated_days")
    private Integer proratedDays;

    @Column(name = "is_electric_meter_reset")
    @Builder.Default
    private Boolean isElectricMeterReset = false;

    @Column(name = "old_electric_meter_final_reading")
    private Double oldElectricMeterFinalReading;

    @Column(name = "is_water_meter_reset")
    @Builder.Default
    private Boolean isWaterMeterReset = false;

    @Column(name = "old_water_meter_final_reading")
    private Double oldWaterMeterFinalReading;

    @Column(name = "type")
    @Builder.Default
    private String type = "MONTHLY"; // MONTHLY, CHECKOUT

    @Column(name = "status")
    @Builder.Default
    private String status = "PENDING"; // PENDING, PAID, DISPUTED

    // --- Service Pool Integration (Dịch vụ dùng chung theo Nhóm) ---
    /** Tổng phí từ các ServicePool mà phòng tham gia */
    @Column(name = "shared_pool_amount")
    private Double sharedPoolAmount;

    /** JSON chi tiết phí từng Pool: {"Điện chung Tầng 2": 100000, "Điện hành lang Tòa": 60000} */
    @Column(name = "service_details", columnDefinition = "TEXT")
    private String serviceDetails;

    @Column(name = "damage_fee")
    private Double damageFee;

    @Column(name = "damage_reason", columnDefinition = "TEXT")
    private String damageReason;

    @Column(name = "is_paid")
    @Builder.Default
    private Boolean isPaid = false;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "paid_by_cash")
    @Builder.Default
    private Boolean paidByCash = false;

    @Column(name = "collected_by_staff_id")
    private Long collectedByStaffId;

    @Column(name = "is_remitted")
    @Builder.Default
    private Boolean isRemitted = false;

    @Column(name = "due_date")
    private LocalDateTime dueDate;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @PrePersist
    @PreUpdate
    public void syncIsPaidWithStatus() {
        if ("PAID".equals(this.status)) {
            this.isPaid = true;
        } else if ("PENDING".equals(this.status) || "PENDING_CASH".equals(this.status)) {
            this.isPaid = false;
        }
    }
}
