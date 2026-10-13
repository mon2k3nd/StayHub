package com.stayhub.api.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class RoomPostDTO {
    private Long id;
    private Long roomId;
    private Long ownerId;
    private String postTitle;
    private String postDescription;
    private String coverImageUrl;
    private String postImages; // JSON Array String
    private Double rentingPrice;
    private Double deposit;
    private Boolean hasPromotion;
    private String discountType;
    private Double discountAmount;
    private Integer promotionMonths;
    private String promotionDescription;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
