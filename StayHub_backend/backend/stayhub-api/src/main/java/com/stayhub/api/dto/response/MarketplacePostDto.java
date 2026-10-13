package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class MarketplacePostDto {
    private Long id;
    private String title;
    private String content;
    private String price;
    private String status;
    private String tag;
    private String tagColor;
    private String author;
    private String room;
    private String time;
    private Double distanceKm;       // null nếu không biết vị trí
    private String distanceLabel;    // VD: "1.2 km" hoặc "Gần bạn"
    private Double latitude;
    private Double longitude;
}
