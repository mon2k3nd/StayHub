package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class MarketplacePostRequestDto {
    private String title;
    private String content;
    private Double price;
    private String tag;
    private String tagColor;
}
