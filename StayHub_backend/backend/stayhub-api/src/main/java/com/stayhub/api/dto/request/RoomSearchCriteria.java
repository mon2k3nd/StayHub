package com.stayhub.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Tiêu chí tìm kiếm phòng công khai (guest marketplace).
 *
 * <p>Đây là "hợp đồng" duy nhất giữa frontend và backend cho tính năng tìm
 * phòng + bộ lọc. Mọi tham số đều nullable — null nghĩa là "không lọc theo
 * tiêu chí đó".</p>
 *
 * <p>Được dựng từ query params ở {@code V1PublicRoomController#searchPublicRooms}
 * và tiêu thụ bởi {@code RoomPostSpecification}.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomSearchCriteria {

    // ── Từ khoá ───────────────────────────────────────────────────────────────
    /** Từ khoá tự do: khớp tiêu đề tin, tên phòng, địa chỉ (mới + cũ), mô tả. */
    private String keyword;

    // ── Giá thuê (VND / tháng) ────────────────────────────────────────────────
    private Double minPrice;
    private Double maxPrice;

    // ── Diện tích (m²) ────────────────────────────────────────────────────────
    private Double minArea;
    private Double maxArea;

    // ── Loại phòng (room_sub_type): PHONG_TRO | STUDIO | GAC_LUNG | ... ───────
    private List<String> roomTypes;

    // ── Số phòng ngủ ──────────────────────────────────────────────────────────
    private Integer bedrooms;

    // ── Số giường ─────────────────────────────────────────────────────────────
    private Integer beds;

    // ── Số phòng tắm / WC ─────────────────────────────────────────────────────
    private Integer bathrooms;

    // ── Số người tối đa ───────────────────────────────────────────────────────
    private Integer maxGuests;

    // ── Hình thức sử dụng: WHOLE (toàn bộ) | SHARED (chung) | PRIVATE (riêng) ─
    private String usageType;

    // ── Tỉnh / Thành phố (khớp address hoặc address_old) ──────────────────────
    private String province;
    
    // ── Quận / Huyện ──────────────────────────────────────────────────────────
    private String district;
    
    // ── Phường / Xã ───────────────────────────────────────────────────────────
    private String ward;

    // ── Hướng phòng: DONG | TAY | NAM | BAC ───────────────────────────────────
    private String direction;

    // ── Tiện ích / nội thất (mã trong cột `furniture`, JSON array) ────────────
    // Ví dụ: ["AC", "WIFI", "HEATER"]. Phòng phải chứa TẤT CẢ mã này (AND).
    private List<String> amenities;

    // ── Đặc điểm phòng ────────────────────────────────────────────────────────
    private Boolean hasWindow;      // có cửa sổ
    private Boolean hasBalcony;     // có ban công
    private Boolean privateBathroom; // WC riêng (bathroom_type = RIENG)
    private Boolean onlyPromotion;  // chỉ hiện tin có khuyến mãi

    // ── Sắp xếp: newest | price_asc | price_desc | area_asc | area_desc ───────
    private String sortBy;

    // ── Vị trí (bounding box) ─────────────────────────────────────────────────
    private Double lat;
    private Double lng;
    private Double radius; // km
}
