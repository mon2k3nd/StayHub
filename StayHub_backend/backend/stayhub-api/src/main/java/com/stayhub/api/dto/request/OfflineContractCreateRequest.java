package com.stayhub.api.dto.request;

import lombok.Data;

@Data
public class OfflineContractCreateRequest {
    private Long roomId;
    private String tenantName;
    private String tenantPhone;
    private String tenantCccd;
    private Double monthlyRent;
    private Double depositAmount;
    private Double electricityPrice;
    private Double waterPrice;
    private Double initialElectricIndex;
    private Double initialWaterIndex;
    private String startDate;
    private String endDate;
    private String terms;


}
