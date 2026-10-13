package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/smart-contracts")
@RequiredArgsConstructor
@CrossOrigin("*")
public class SmartContractExtensionController {

    // Simple extension for Lease Renewal and Hash Verification
    
    @PostMapping("/renew/{contractId}")
    public ResponseEntity<ApiResponse<Boolean>> renewLease(@PathVariable Long contractId, @RequestParam int additionalMonths) {
        // Mock logic: Duplicate contract and update end date
        return ResponseEntity.ok(ApiResponse.<Boolean>builder()
                .success(true)
                .message("Đã gia hạn hợp đồng thành công thêm " + additionalMonths + " tháng")
                .data(true)
                .build());
    }

    @GetMapping("/hash/{contractId}")
    public ResponseEntity<ApiResponse<String>> verifyHash(@PathVariable Long contractId) {
        // Mock logic: return a fake hash string for the signature using java.util.UUID to avoid missing dependencies
        String fakeHash = "0x" + java.util.UUID.randomUUID().toString().replace("-", "");
        return ResponseEntity.ok(ApiResponse.<String>builder()
                .success(true)
                .message("Lấy chuỗi Hash xác minh chữ ký thành công")
                .data(fakeHash)
                .build());
    }
}
