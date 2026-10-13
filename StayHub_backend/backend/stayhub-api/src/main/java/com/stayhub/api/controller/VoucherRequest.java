package com.stayhub.api.controller;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class VoucherRequest {
    private String code;
    private String discountType;
    private Double discountAmount;
    private Double discountPercent;
    private Double maxDiscountAmount;
    private Integer monthsPerTenant;
    private Integer totalUsageLimit;
    private LocalDate startDate;
    private LocalDate endDate;
    private String description;
    private List<Long> roomIds;
    private Boolean applyAllRooms;
    private Long branchId;
}
