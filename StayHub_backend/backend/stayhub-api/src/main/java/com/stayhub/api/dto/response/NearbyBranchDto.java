package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class NearbyBranchDto {
    private Long id;
    private String branchName;
    private String branchCode;
    private String address;       // backward compat (= addressOld)
    private String addressOld;    // Địa chỉ cũ 4 cấp: dùng trên Map/UI

    private Double latitude;
    private Double longitude;
    private Double distanceKm;
    private String distanceLabel;
    private Integer availableRooms;   // số phòng trống
    private Double minPrice;          // giá thấp nhất trong chi nhánh
    private Double maxPrice;
    private String coverImageUrl;
    private List<String> imageUrls;
    private String propertyType;
    private Double electricityPrice;
    private Double waterPrice;
}
