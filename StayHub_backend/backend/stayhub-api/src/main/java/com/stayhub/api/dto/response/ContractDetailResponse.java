package com.stayhub.api.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class ContractDetailResponse {
    // Contract base info
    private Long id;
    private String status;
    private LocalDate startDate;
    private LocalDate endDate;
    private Double monthlyRent;
    private Double depositAmount;
    private Double electricityPrice;
    private Double waterPrice;
    private Double serviceFee;
    private String terms;
    private LocalDateTime signedAt;
    private LocalDateTime createdAt;

    private String handoverCondition;
    private String ownerSignature;
    private String tenantSignature;

    // Room info
    private Long roomId;
    private String roomName;
    private String roomAddress;
    private String roomCode;
    private Integer floor;
    private Double floorArea;

    // Branch info
    private Long branchId;
    private String branchName;
    private String branchAddress;

    // Tenant info
    private Long tenantId;
    private String tenantName;
    private String tenantPhone;
    private String tenantEmail;
    private String tenantCccd;
    private String tenantHometown;
    private String tenantOccupation;

    // Owner info
    private Long ownerId;
    private String ownerName;
    private String ownerPhone;
    private String ownerEmail;
}
