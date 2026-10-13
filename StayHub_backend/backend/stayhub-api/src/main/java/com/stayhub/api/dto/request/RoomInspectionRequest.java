package com.stayhub.api.dto.request;

import lombok.Data;
import java.util.List;

@Data
public class RoomInspectionRequest {
    private Long roomId;
    private Long tenantId;
    private String type;
    private String notes;
    private String tenantSignatureUrl;
    private String staffSignatureUrl;
    private List<InspectionItemRequest> items;
}
