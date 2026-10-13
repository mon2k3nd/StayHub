package com.stayhub.api.service;

import com.stayhub.api.dto.response.ContractDetailResponse;
import com.stayhub.api.entity.Contract;
import java.util.List;
import java.util.Map;

public interface ContractService {
    List<Contract> getByTenant(Long tenantId);
    List<Contract> getByOwner(Long ownerId);
    Contract getActiveByRoom(Long roomId);
    Contract create(Contract contract);
    Contract terminate(Long id, String reason);
    Contract terminate(Long id, Long requesterId, String reason);
    Contract renew(Long id, int months);
    Contract renew(Long id, Long requesterId, int months);
    Map<String, Object> liquidate(Long id, Map<String, Object> data);
    Contract verifyContract(Long id, Long tenantId, java.util.List<org.springframework.web.multipart.MultipartFile> contractImages, org.springframework.web.multipart.MultipartFile electricityMeterImage, org.springframework.web.multipart.MultipartFile waterMeterImage, java.util.List<org.springframework.web.multipart.MultipartFile> inspectionImages, java.util.List<org.springframework.web.multipart.MultipartFile> furnitureImages, java.util.List<String> furnitureNotes);
    Contract offlineVerifyContract(Long id, Long ownerId, java.util.List<org.springframework.web.multipart.MultipartFile> contractImages, java.util.List<org.springframework.web.multipart.MultipartFile> cccdImages);
    Object getInspectionLog(Long contractId, Long tenantId);
    ContractDetailResponse getContractDetail(Long contractId);
    Contract tenantSignContract(Long contractId, Long tenantId, String tenantSignature, String handoverCondition);
    Contract offlineCreateContract(Long ownerId, com.stayhub.api.dto.request.OfflineContractCreateRequest request);
    Contract cancelOfflineContract(Long contractId, Long ownerId);
}
