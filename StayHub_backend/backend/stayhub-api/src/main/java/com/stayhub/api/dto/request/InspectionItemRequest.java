package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class InspectionItemRequest {
    private String itemName;
    private Boolean isGood;
    private String notes;
    private String photoUrl;
}
