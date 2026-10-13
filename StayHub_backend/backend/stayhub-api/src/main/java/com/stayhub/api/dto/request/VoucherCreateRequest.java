package com.stayhub.api.dto.request;

import com.stayhub.api.entity.Voucher;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class VoucherCreateRequest {
    
    @NotBlank(message = "Mã voucher không được để trống")
    private String code;
    
    @NotNull
    private Voucher.DiscountType discountType;
    
    @NotNull
    private Double discountAmount;
    
    private Double discountPercent;
    
    private Double maxDiscountAmount;
    
    @NotNull
    private Voucher.AppliesToTarget appliesToTarget;
    
    @NotNull
    private Voucher.ScopeType scopeType;
    
    private Long branchId;
    
    private Boolean applyAllRooms;
    
    private String targetIds; // JSON array string
    
    @NotNull
    private Integer totalUsageLimit;
    
    @NotNull
    private Integer monthsPerTenant;
    
}
