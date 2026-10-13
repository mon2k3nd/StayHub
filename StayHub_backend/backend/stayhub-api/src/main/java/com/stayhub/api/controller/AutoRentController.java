package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Bill;
import com.stayhub.api.service.AutoRentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auto-rent")
@RequiredArgsConstructor
@CrossOrigin("*")
public class AutoRentController {

    private final AutoRentService autoRentService;

    @PostMapping("/enable/{contractId}")
    public ResponseEntity<ApiResponse<Boolean>> enableAutoRent(@PathVariable Long contractId) {
        autoRentService.enableAutoRent(contractId);
        return ResponseEntity.ok(ApiResponse.<Boolean>builder()
                .success(true).message("Đã kích hoạt thu tiền tự động")
                .data(true).build());
    }

    @PostMapping("/split/{billId}")
    public ResponseEntity<ApiResponse<List<Bill>>> splitBill(@PathVariable Long billId, @RequestBody Map<String, List<Long>> body) {
        List<Long> tenantIds = body.get("tenantIds");
        List<Bill> splitBills = autoRentService.splitBill(billId, tenantIds);
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Đã chia nhỏ hóa đơn")
                .data(splitBills).build());
    }
}
