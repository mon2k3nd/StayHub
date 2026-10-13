package com.stayhub.api.controller;

import com.stayhub.api.dto.request.RoomSearchCriteria;
import com.stayhub.api.dto.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * API công khai cho khách (guest) tìm phòng + lọc.
 *
 * <p>Base path: {@code /v1/rooms/public}. Tất cả endpoint ở đây đều public
 * (không cần đăng nhập) — xem {@code SecurityConfig}.</p>
 */
@RestController
@RequestMapping("/v1/rooms/public")
@RequiredArgsConstructor
public class V1PublicRoomController {

    private final com.stayhub.api.service.RoomPostService roomPostService;

    /** Danh sách tin đăng công khai (không lọc), có phân trang. */
    @GetMapping
    public ResponseEntity<ApiResponse<Page<com.stayhub.api.dto.MarketplacePostDTO>>> getPublicRooms(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<com.stayhub.api.dto.MarketplacePostDTO> publicPosts =
                roomPostService.getPublicPosts(PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.<Page<com.stayhub.api.dto.MarketplacePostDTO>>builder()
                .success(true)
                .message("Lấy danh sách tin đăng công khai thành công")
                .data(publicPosts)
                .build());
    }

    /**
     * Tìm kiếm + lọc phòng công khai.
     *
     * <p>Mọi tham số đều tuỳ chọn. Bỏ trống = không lọc theo tiêu chí đó.
     * Toàn bộ lọc chạy ở DB nên phân trang chính xác trên toàn bộ tập kết quả.</p>
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<com.stayhub.api.dto.MarketplacePostDTO>>> searchPublicRooms(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) Double minArea,
            @RequestParam(required = false) Double maxArea,
            @RequestParam(required = false) List<String> roomTypes,
            @RequestParam(required = false) Integer bedrooms,
            @RequestParam(required = false) Integer beds,
            @RequestParam(required = false) Integer bathrooms,
            @RequestParam(required = false) Integer maxGuests,
            @RequestParam(required = false) String usageType,
            @RequestParam(required = false) String province,
            // BUGFIX: thiếu `district` + `ward` → frontend gửi lên nhưng Spring
            // bỏ qua (không có param để bind) → bộ lọc Quận/Huyện + Phường/Xã
            // IM LẶNG không có tác dụng, dù RoomPostSpecification đã đọc
            // c.getDistrict()/c.getWard(). Bổ sung để khớp contract.
            @RequestParam(required = false) String district,
            @RequestParam(required = false) String ward,
            @RequestParam(required = false) String direction,
            @RequestParam(required = false) List<String> amenities,
            @RequestParam(required = false) Boolean hasWindow,
            @RequestParam(required = false) Boolean hasBalcony,
            @RequestParam(required = false) Boolean privateBathroom,
            @RequestParam(required = false) Boolean onlyPromotion,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radius,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        RoomSearchCriteria criteria = RoomSearchCriteria.builder()
                .keyword(keyword)
                .minPrice(minPrice)
                .maxPrice(maxPrice)
                .minArea(minArea)
                .maxArea(maxArea)
                .roomTypes(roomTypes)
                .bedrooms(bedrooms)
                .beds(beds)
                .bathrooms(bathrooms)
                .maxGuests(maxGuests)
                .usageType(usageType)
                .province(province)
                .district(district)
                .ward(ward)
                .direction(direction)
                .amenities(amenities)
                .hasWindow(hasWindow)
                .hasBalcony(hasBalcony)
                .privateBathroom(privateBathroom)
                .onlyPromotion(onlyPromotion)
                .sortBy(sortBy)
                .lat(lat)
                .lng(lng)
                .radius(radius)
                .build();

        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 50));
        Page<com.stayhub.api.dto.MarketplacePostDTO> results =
                roomPostService.searchPublicPosts(criteria, pageable);

        return ResponseEntity.ok(ApiResponse.<Page<com.stayhub.api.dto.MarketplacePostDTO>>builder()
                .success(true)
                .message("Tìm kiếm tin đăng công khai thành công")
                .data(results)
                .build());
    }

    /**
     * Metadata cho bộ lọc: khoảng giá/diện tích thực tế, danh sách loại phòng
     * và tiện ích đang có. Frontend dùng để dựng slider + chip động.
     */
    @GetMapping("/filters")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFilterMetadata() {
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Lấy cấu hình bộ lọc thành công")
                .data(roomPostService.getFilterMetadata())
                .build());
    }

    /** Chi tiết một tin đăng công khai. */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<com.stayhub.api.dto.MarketplacePostDTO>> getPublicRoomDetail(
            @PathVariable Long id
    ) {
        com.stayhub.api.dto.MarketplacePostDTO post = roomPostService.getPostDetail(id);
        return ResponseEntity.ok(ApiResponse.<com.stayhub.api.dto.MarketplacePostDTO>builder()
                .success(true)
                .message("Lấy chi tiết phòng thành công")
                .data(post)
                .build());
    }
}
