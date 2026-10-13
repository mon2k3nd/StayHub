package com.stayhub.api.dto;

import com.stayhub.api.entity.Voucher.DiscountType;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class MarketplacePostDTO {
    // ── Room core fields ──────────────────────────────────────────────────────
    private Long id;
    private Long ownerId;
    private Long branchId;
    private String roomName;
    private Double price;
    private String address;       // backward compat (= addressOld)
    private String addressOld;    // Địa chỉ cũ 4 cấp: dùng trên UI/Map

    private String status;
    private String description;
    private Double floorArea;
    private String furniture;        // JSON array amenity codes e.g. ["WIFI","AC"]
    private String videoUrl;
    private String pois;
    private Double latitude;
    private Double longitude;
    private Integer maxGuests;
    private Integer bedrooms;
    private Integer beds;
    private Integer bathrooms;
    private Double electricityPrice;
    private Double waterPrice;
    private Double serviceFee;
    private Boolean hasBalcony;
    private Boolean hasWindow;

    // ── Room detail fields (real data from DB) ────────────────────────────────
    private Integer floor;           // tầng
    private String direction;        // hướng: DONG | TAY | NAM | BAC
    private String bathroomType;     // RIENG | CHUNG
    private Double area;             // alias floorArea for frontend compat
    private Double deposit;
    private String roomCode;

    // ── Ảnh phòng (cột TEXT `room_images`, CSV hoặc JSON array) ───────────────
    // Preview dựng gallery từ `roomImages`; trang đã đăng trước đây KHÔNG nhận
    // được field này nên gallery rỗng/lệch thứ tự. Trả nguyên vẹn để khớp preview.
    private String roomImages;

    // ── Các field cấu hình phòng còn thiếu (wizard bước 2/3) ──────────────────
    // (addressOld đã khai báo ở trên — không khai báo lại để tránh trùng field)
    private Double mezzanineArea;           // diện tích gác lửng
    private Integer maxVehicles;            // số xe tối đa
    private java.time.LocalDate availableFrom; // ngày có thể vào ở
    private String roomSubType;             // PHONG_TRO | STUDIO | GAC_LUNG ...
    // Alias của roomSubType để frontend đọc `room['roomType']` nhận đúng MÃ
    // canonical (trước đây field này không tồn tại → frontend rơi về mặc định
    // "Phòng trọ" hoặc hiển thị sai loại). Luôn là MÃ, KHÔNG phải nhãn.
    private String roomType;
    private Boolean isSharedWc;             // dùng WC chung?
    private String sharedWcId;              // mã khu WC chung
    private Double oldElectricityIndex;     // chỉ số điện ban đầu
    private Double oldWaterIndex;           // chỉ số nước ban đầu
    private Boolean hasPrivateElectricMeter;
    private Boolean hasPrivateWaterMeter;
    private String electricityPricingType;  // PER_KWH | PER_PERSON | FIXED
    private String serviceFeePricingType;   // PER_ROOM | PER_PERSON | FIXED

    // ── Ghi đè dịch vụ cấp phòng (override_services) ──────────────────────────
    // Khi overrideServices = true, giá rác/mạng/gửi xe của PHÒNG thắng giá Branch.
    private Boolean overrideServices;
    private Double overrideGarbageFee;
    private Double overrideInternetFee;
    private Double overrideParkingFee;

    // ── Full 5-step room configuration (bước cấu hình phòng khi tạo chi nhánh) ─
    // Toàn bộ dữ liệu nhập ở wizard (nội thất, chỉ số đồng hồ, ảnh đặc trưng,
    // số người tối đa, hướng, loại phòng...) nằm trong cột jsonb `detailed_info`.
    // Trước đây DTO KHÔNG mang field này → trang chi tiết phòng đã đăng bị mất
    // toàn bộ nội dung so với lúc xem trước. Bổ sung để preview == published.
    private java.util.Map<String, Object> detailedInfo;

    // ── Branch (toà nhà) info — nguồn giá dịch vụ + tiện ích chung ────────────
    // Chi tiết phòng đọc giá điện/nước/mạng/gửi xe/rác/phí dịch vụ và danh sách
    // tiện ích chung từ object `branch`. Không có các field này thì phần "Chi phí"
    // và "Tiện ích toà nhà" sẽ trống trên trang đã đăng.
    private String branchName;
    private String branchAddress;
    // BUGFIX: toạ độ của TOÀ NHÀ. Phòng có thể chưa gắn lat/lng nhưng chi nhánh thì
    // có → "Tiện ích xung quanh" (POI) ở trang đã đăng bị trống/lệch so với preview.
    // Trả kèm để frontend fallback khi room.latitude/longitude null.
    private Double branchLatitude;
    private Double branchLongitude;
    private Double internetPrice;
    private Double parkingPrice;
    private Double trashPrice;
    private String waterPricingType;
    private java.util.List<java.util.Map<String, Object>> branchAmenities;

    // ── Owner info ────────────────────────────────────────────────────────────
    private String ownerName;
    private String ownerPhone;
    private String ownerAvatar;
    private Boolean isSuperLandlord;

    // ── Post fields ───────────────────────────────────────────────────────────
    private Long postId;
    private String postTitle;
    // BUGFIX: frontend (feed card + detail sheet) đọc `room['title']` để hiển thị
    // tiêu đề tin đăng. DTO công khai trước đây KHÔNG có field `title` → luôn rơi
    // về `roomName` (tên phòng) → tiêu đề bài đăng sai. Trả `title` = postTitle.
    private String title;
    private String coverImageUrl;
    private String postImages;
    private String postStatus;
    private LocalDateTime postCreatedAt;

    // ── Promotion fields (from room_promotions table) ─────────────────────────
    private Boolean hasPromotion;
    private Long promotionId;
    private DiscountType discountType;
    private Double discountAmount;       // số tiền giảm (FIXED_AMOUNT)
    private Double discountPercent;      // % giảm (PERCENTAGE)
    private Double maxDiscountAmount;
    private Integer monthsPerTenant;     // số tháng được giảm mỗi tenant
    private Integer totalMonths;
    private Integer usedMonths;
    private Integer remainingMonths;     // -1 = unlimited
    private Double originalPrice;        // = price (giá gốc)
    private Double promotionPrice;       // giá sau giảm
    private String badgeLabel;           // "20% OFF" | "-500,000đ"
    private String promotionDescription;
    private LocalDate promotionEndDate;

    // ── Engagement fields ─────────────────────────────────────────────────────
    private Integer wishlistCount;   // số người đã lưu phòng này
}
