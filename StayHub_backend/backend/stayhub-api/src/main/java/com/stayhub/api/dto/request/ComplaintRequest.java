package com.stayhub.api.dto.request;

import lombok.Data;
import java.util.List;

@Data
public class ComplaintRequest {
    private Long branchId;
    private Long roomId;
    private String category;
    private String priority; // LOW, MEDIUM, HIGH, URGENT
    private String title;
    private String description;
    private List<String> images; // List of image URLs
}
