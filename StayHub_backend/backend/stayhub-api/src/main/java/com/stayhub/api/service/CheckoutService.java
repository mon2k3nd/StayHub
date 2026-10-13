package com.stayhub.api.service;

import com.stayhub.api.dto.CheckoutRequestDto;
import com.stayhub.api.dto.CreateCheckoutBillDto;
import com.stayhub.api.entity.CheckoutRequest;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;

public interface CheckoutService {
    CheckoutRequest createCheckoutRequest(CheckoutRequestDto dto, List<MultipartFile> files);
    List<CheckoutRequest> getRequestsForOwner(Long ownerId);
    List<CheckoutRequest> getRequestsForTenant(Long tenantId);
    CheckoutRequest rejectRequest(Long id, String ownerReason);
    Map<String, Object> approveAndCreateBill(Long id, CreateCheckoutBillDto billDto);
    String analyzeImagesWithAI(Long id);
    void completeCheckoutAndFreeRoom(Long billId);
    Map<String, Object> getTrackingSummary(Long id);
    Map<String, Object> getCheckoutDetails(Long id);
}
