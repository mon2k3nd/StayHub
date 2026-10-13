package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import jakarta.validation.constraints.Min;

@Entity
@Table(name = "rooms", indexes = {
    @Index(name = "idx_room_owner", columnList = "owner_id"),
    @Index(name = "idx_room_branch", columnList = "branch_id")
})
@org.hibernate.annotations.SQLRestriction("is_deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "branch_id")
    private Long branchId;

    @Column(name = "room_name", nullable = false)
    private String roomName;

    @Min(0)
    @Column(name = "price")
    private Double price;

    @Column(name = "address")
    private String address;

    /** Địa chỉ cũ 4 cấp (63 tỉnh): kế thừa từ Branch, dùng cho UI/Map */
    @Column(name = "address_old", length = 512)
    private String addressOld;


    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    @Builder.Default
    private RoomStatus status = RoomStatus.TRONG;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Min(0)
    @Column(name = "deposit")
    private Double deposit;

    @Min(0)
    @Column(name = "max_guests")
    private Integer maxGuests;

    @Min(0)
    @Column(name = "bedrooms")
    private Integer bedrooms;

    @Min(0)
    @Column(name = "beds")
    private Integer beds;

    @Min(0)
    @Column(name = "bathrooms")
    private Integer bathrooms;

    @Min(0)
    @Column(name = "electricity_price")
    private Double electricityPrice;

    @Min(0)
    @Column(name = "water_price")
    private Double waterPrice;

    @Enumerated(EnumType.STRING)
    @Column(name = "water_pricing_type")
    private PricingType waterPricingType;

    @Enumerated(EnumType.STRING)
    @Column(name = "electricity_pricing_type")
    private PricingType electricityPricingType;

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(name = "approval_status")
    @Builder.Default
    private String approvalStatus = "APPROVED"; // "APPROVED" or "PENDING_APPROVAL"

    @Enumerated(EnumType.STRING)
    @Column(name = "service_fee_pricing_type")
    private PricingType serviceFeePricingType;

    @Min(0)
    @Column(name = "service_fee")
    private Double serviceFee;

    @Column(name = "room_images", columnDefinition = "TEXT")
    private String roomImages;

    @Column(name = "inspection_images", columnDefinition = "TEXT")
    private String inspectionImages;

    // Mã QR tự động sinh khi tạo phòng: base64 hoặc URL ảnh QR
    @Column(name = "qr_code", columnDefinition = "TEXT")
    private String qrCode;
    @Column(name = "active_otp_code")
    private String activeOtpCode;
    @Column(name = "otp_expired_at")
    private LocalDateTime otpExpiredAt;
    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    // Phòng đang có khách thuê
    @Column(name = "current_tenant_id")
    private Long currentTenantId;

    @Column(name = "current_contract_id")
    private Long currentContractId;

    @Column(name = "property_id")
    private Long propertyId;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "detailed_info", columnDefinition = "jsonb")
    private java.util.Map<String, Object> detailedInfo;

    // --- Mở rộng Dữ liệu theo Đặc tả chi tiết ---
    @Column(name = "room_code", unique = true, length = 50)
    private String roomCode;

    @Column(name = "floor")
    private Integer floor;

    @Column(name = "floor_area")
    private Double floorArea;

    @Column(name = "mezzanine_area")
    private Double mezzanineArea;

    @Column(name = "base_deposit")
    private Double baseDeposit;

    @Column(name = "max_vehicles")
    @Builder.Default
    private Integer maxVehicles = 2;

    @Column(name = "is_public")
    @Builder.Default
    private Boolean isPublic = false;

    @Column(name = "video_url")
    private String videoUrl;

    @Column(name = "pois", columnDefinition = "TEXT")
    private String pois;

    // --- Geolocation ---
    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    // --- Thông tin chi tiết phòng ---
    @Column(name = "furniture", columnDefinition = "TEXT")
    private String furniture; // JSON array: ["AC","GIƯỜNG","TV"...]

    @Column(name = "bathroom_type", length = 20)
    @Builder.Default
    private String bathroomType = "CHUNG"; // RIENG | CHUNG

    // ─── Bước 2/3: Cấu hình WC chung & loại phòng chi tiết ───
    /** true = phòng dùng WC chung (không khép kín). Đồng bộ với bathroomType == "CHUNG". */
    @Column(name = "is_shared_wc")
    @Builder.Default
    private Boolean isSharedWc = false;

    /** Mã khu WC chung mà phòng này được gán vào (VD: "WC01"). Null nếu phòng khép kín. */
    @Column(name = "shared_wc_id", length = 50)
    private String sharedWcId;

    /** Loại phòng con: PHONG_TRO | STUDIO | GAC_LUNG | PHONG_DON | CHDV ... */
    @Column(name = "room_sub_type", length = 30)
    private String roomSubType;

    // ─── Bước 2: Chỉ số ban đầu & đồng hồ phụ ───
    /** Chỉ số điện ban đầu (Old Index) khi khởi tạo phòng. */
    @Column(name = "old_electricity_index")
    private Double oldElectricityIndex;

    /** Chỉ số nước ban đầu (Old Index) khi khởi tạo phòng. */
    @Column(name = "old_water_index")
    private Double oldWaterIndex;

    /** true = phòng có đồng hồ điện riêng gắn tường (không dùng đồng hồ tổng). */
    @Column(name = "has_private_electric_meter")
    @Builder.Default
    private Boolean hasPrivateElectricMeter = false;

    /** true = phòng có đồng hồ nước riêng gắn tường (không dùng đồng hồ tổng). */
    @Column(name = "has_private_water_meter")
    @Builder.Default
    private Boolean hasPrivateWaterMeter = false;

    // ─── Bước 2: Cơ chế ghi đè dịch vụ (Override Services) ───
    /**
     * true = phòng này ghi đè bộ đơn giá của chi nhánh (VD: miễn phí rác, giá điện ưu đãi).
     * Khi false, mọi giá dịch vụ lấy mặc định từ Branch.
     */
    @Column(name = "override_services")
    @Builder.Default
    private Boolean overrideServices = false;

    /** Giá rác riêng của phòng (chỉ dùng khi overrideServices = true). */
    @Column(name = "override_garbage_fee")
    private Double overrideGarbageFee;

    /** Giá internet riêng của phòng (chỉ dùng khi overrideServices = true). */
    @Column(name = "override_internet_fee")
    private Double overrideInternetFee;

    /** Giá gửi xe riêng của phòng (chỉ dùng khi overrideServices = true). */
    @Column(name = "override_parking_fee")
    private Double overrideParkingFee;

    @Column(name = "direction", length = 10)
    private String direction; // DONG | TAY | NAM | BAC

    @Column(name = "has_balcony")
    @Builder.Default
    private Boolean hasBalcony = false;

    @Column(name = "has_window")
    @Builder.Default
    private Boolean hasWindow = true;

    @Column(name = "available_from")
    private java.time.LocalDate availableFrom;

    @ManyToMany(mappedBy = "rooms", fetch = jakarta.persistence.FetchType.EAGER)
    private List<SharedFacility> sharedFacilities;

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }
    public Double getFloorArea() { return floorArea; }
    public void setFloorArea(Double floorArea) { this.floorArea = floorArea; }
}
