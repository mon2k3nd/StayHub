package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.SaasMarketingCampaign;
import com.stayhub.api.service.MarketingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/marketing")
@RequiredArgsConstructor
@CrossOrigin("*")
public class MarketingController {

    private final MarketingService marketingService;

    @GetMapping("/campaigns")
    public ResponseEntity<ApiResponse<List<SaasMarketingCampaign>>> getCampaigns() {
        return ResponseEntity.ok(ApiResponse.<List<SaasMarketingCampaign>>builder()
                .success(true)
                .message("Lấy danh sách chiến dịch thành công")
                .data(marketingService.getAllActiveCampaigns())
                .build());
    }

    @PostMapping("/campaigns")
    public ResponseEntity<ApiResponse<SaasMarketingCampaign>> createCampaign(@RequestBody SaasMarketingCampaign campaign) {
        return ResponseEntity.ok(ApiResponse.<SaasMarketingCampaign>builder()
                .success(true)
                .message("Tạo chiến dịch thành công")
                .data(marketingService.createCampaign(campaign))
                .build());
    }

    @PostMapping("/campaigns/{id}/push")
    public ResponseEntity<ApiResponse<Boolean>> pushNotification(@PathVariable Long id) {
        marketingService.pushNotification(id);
        return ResponseEntity.ok(ApiResponse.<Boolean>builder()
                .success(true)
                .message("Đã gửi Push Notification")
                .data(true)
                .build());
    }
}
