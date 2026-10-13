package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "branches", indexes = {
    @Index(name = "idx_branch_owner", columnList = "owner_id")
})
@org.hibernate.annotations.SQLRestriction("is_deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Branch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "branch_name", nullable = false)
    private String branchName;

    @Column(name = "address", nullable = false)
    private String address;

    /** Địa chỉ cũ 4 cấp (63 tỉnh): dùng cho UI, Search/Filter, Maps */
    @Column(name = "address_old", length = 512)
    private String addressOld;


    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "pois", columnDefinition = "TEXT")
    private String pois;

    @Column(name = "amenities", columnDefinition = "TEXT")
    private String amenities;

    @Column(name = "internet_fee")
    @Builder.Default
    private Double internetFee = 0.0;

    @Column(name = "parking_fee")
    @Builder.Default
    private Double parkingFee = 0.0;

    @Column(name = "garbage_fee")
    @Builder.Default
    private Double garbageFee = 0.0;

    @Column(name = "total_rooms")
    @Builder.Default
    private Integer totalRooms = 0;

    @Transient
    private Integer numberOfFloors;

    @Transient
    private Integer roomsPerFloor;

    @Transient
    private java.util.List<Integer> roomsPerFloorList;

    @Column(name = "cover_image")
    private String coverImage;

    @Column(name = "electricity_price")
    private Double electricityPrice;

    @Column(name = "water_price")
    private Double waterPrice;

    @Enumerated(EnumType.STRING)
    @Column(name = "water_pricing_type")
    @Builder.Default
    private PricingType waterPricingType = PricingType.PER_INDEX;

    @Enumerated(EnumType.STRING)
    @Column(name = "electricity_pricing_type")
    @Builder.Default
    private PricingType electricityPricingType = PricingType.PER_INDEX;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_fee_pricing_type")
    @Builder.Default
    private PricingType serviceFeePricingType = PricingType.PER_ROOM;

    @Column(name = "service_fee")
    @Builder.Default
    private Double serviceFee = 0.0;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    // --- Mở rộng Dữ liệu theo Đặc tả chi tiết ---
    @Column(name = "branch_code", unique = true, length = 50)
    private String branchCode;

    /**
     * Mã gốc được giữ lại khi chi nhánh bị TẠM NGỪNG (SUSPENDED).
     *
     * <p>Lý do: cột {@code branch_code} có UNIQUE INDEX ở tầng DB. Khi tạm ngừng
     * chi nhánh, ta "nhả" mã ra để chủ trọ có thể tạo lại chi nhánh mới cùng mã.
     * Muốn vậy phải đổi {@code branchCode} sang một giá trị tạm duy nhất và lưu
     * mã gốc vào đây; khi kích hoạt lại sẽ khôi phục từ cột này.
     */
    @Column(name = "suspended_code", length = 50)
    private String suspendedCode;

    @Column(name = "ward_code", length = 20)
    private String wardCode;

    @Column(name = "district_code", length = 20)
    private String districtCode;

    @Column(name = "province_code", length = 20)
    private String provinceCode;

    /** Địa chỉ mới 3 cấp (34 tỉnh): dùng cho Hợp đồng, eKYC (2026) */
    @Column(name = "legal_ward", length = 100)
    private String legalWard;

    @Column(name = "legal_district", length = 100)
    private String legalDistrict; // Optional, might be empty due to new policy

    @Column(name = "legal_province", length = 100)
    private String legalProvince;

    @Column(name = "property_type")
    private Integer propertyType;

    @Column(name = "billing_day")
    @Builder.Default
    private Integer billingDay = 25;

    @Column(name = "payment_grace_period")
    @Builder.Default
    private Integer paymentGracePeriod = 5;

    @Column(name = "late_fee_percent")
    @Builder.Default
    private Double lateFeePercent = 0.0;

    @Column(name = "management_type")
    private Integer managementType;

    // --- Chính sách dãy trọ ---
    @Column(name = "gender_policy", length = 20)
    @Builder.Default
    private String genderPolicy = "HET"; // NAM | NU | HET (hỗn hợp)

    @Column(name = "pet_policy")
    @Builder.Default
    private Boolean petPolicy = false;

    @Column(name = "deposit_months")
    @Builder.Default
    private Integer depositMonths = 2;

    @Column(name = "min_lease_days")
    @Builder.Default
    private Integer minLeaseDays = 30; // 30/90/180/365

    @Column(name = "closing_time", length = 10)
    @Builder.Default
    private String closingTime = "22:00";

    @Column(name = "cooking_policy", length = 20)
    @Builder.Default
    private String cookingPolicy = "BEP_CHUNG"; // CAM | BEP_CHUNG | TRONG_PHONG

    @Column(name = "roommate_policy")
    @Builder.Default
    private Boolean roommatePolicy = true;

    /**
     * JSON array of base64 or URLs.
     *
     * <p>KHÔNG serialize ra JSON response: đây là cột TEXT chứa ảnh base64
     * (có thể vài MB mỗi chi nhánh). Nếu trả về trong các API danh sách/chi tiết
     * sẽ làm phình heap và gây {@code OutOfMemoryError}. Frontend chỉ cần đọc
     * trường này khi vào màn SỬA — lúc đó gọi API riêng {@code /images}.
     * Vẫn cho phép GHI (deserialize) qua {@link #setCoverImages(String)}.
     */
    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "cover_images", columnDefinition = "TEXT")
    private String coverImages;

    @Column(name = "has_pccc")
    @Builder.Default
    private Boolean hasPccc = false;

    /** Xem chú thích tại {@link #coverImages}. */
    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "pccc_images", columnDefinition = "TEXT")
    private String pcccImages;

    /** Cho phép client GỬI ảnh lên (create/update) dù field bị @JsonIgnore khi đọc. */
    @com.fasterxml.jackson.annotation.JsonProperty("coverImages")
    public void setCoverImages(String coverImages) {
        this.coverImages = coverImages;
    }

    /** Cho phép client GỬI ảnh PCCC lên (create/update) dù field bị @JsonIgnore khi đọc. */
    @com.fasterxml.jackson.annotation.JsonProperty("pcccImages")
    public void setPcccImages(String pcccImages) {
        this.pcccImages = pcccImages;
    }

    @Column(name = "ev_charging_allowed")
    @Builder.Default
    private Boolean evChargingAllowed = false;

    @Column(name = "ev_charge_type", length = 20)
    @Builder.Default
    private String evChargeType = "fixed"; // fixed | metered

    @Column(name = "ev_fixed_price")
    private Double evFixedPrice;

    /**
     * Trạng thái vòng đời của chi nhánh:
     *  - DRAFT     : đang khởi tạo, chưa hoàn tất đủ 4 bước (KHÔNG thống kê, KHÔNG lên chợ trọ)
     *  - COMPLETED : đã hoàn tất đủ 4 bước, đang hoạt động (được thống kê + đăng bài)
     *  - SUSPENDED : chủ nhà tạm ngừng hoạt động (giữ dữ liệu, ẩn khỏi chợ trọ)
     */
    @Column(name = "creation_status", length = 20)
    @Builder.Default
    private String creationStatus = "DRAFT"; // DRAFT | COMPLETED | SUSPENDED

    // ─── Tiến độ hoàn thành từng bước của wizard "Quản lý chi nhánh" ───
    // Chỉ khi CẢ 5 bước đều true thì creationStatus mới được chuyển sang COMPLETED.
    @Column(name = "step1_done")
    @Builder.Default
    private Boolean step1Done = false; // Khung vận hành (ảnh, tên, ID, địa chỉ, mô hình, quy chế, tài sản chung, đơn giá)

    @Column(name = "step2_done")
    @Builder.Default
    private Boolean step2Done = false; // Tài sản chung của toà nhà

    @Column(name = "step3_done")
    @Builder.Default
    private Boolean step3Done = false; // Cấu trúc không gian & WC chung

    @Column(name = "step4_done")
    @Builder.Default
    private Boolean step4Done = false; // Cấu hình phòng chi tiết

    @Column(name = "step5_done")
    @Builder.Default
    private Boolean step5Done = false; // Xác nhận & đăng bài

    /** Thời điểm chi nhánh được chốt hoàn tất (chuyển sang COMPLETED). */
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(name = "approval_status")
    @Builder.Default
    private String approvalStatus = "APPROVED"; // "APPROVED" or "PENDING_APPROVAL"

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
