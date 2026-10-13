package com.stayhub.api.controller;

import com.stayhub.api.config.CheckRole;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.TenantBlacklist;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.TenantBlacklistRepository;
import com.stayhub.api.service.TenantBlacklistService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/tenants")
@RequiredArgsConstructor
@Slf4j
public class V1TenantBlacklistController {

    private final TenantBlacklistService tenantBlacklistService;
    private final TenantBlacklistRepository tenantBlacklistRepository;
    private final ContractRepository contractRepository;

    @PostMapping("/{tenantId}/blacklist")
    @CheckRole({"OWNER"})
    public ResponseEntity<ApiResponse<TenantBlacklist>> reportBlacklist(
            @PathVariable Long tenantId,
            @RequestBody Map<String, String> request,
            Authentication auth) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        Long ownerId = (Long) auth.getPrincipal();
        String reason = request.get("reason");
        String proofUrl = request.get("proofUrl");

        if (reason == null || reason.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Lý do không được để trống");
        }

        TenantBlacklist blacklist = tenantBlacklistService.reportBlacklist(tenantId, ownerId, reason, proofUrl);

        return ResponseEntity.ok(ApiResponse.<TenantBlacklist>builder()
                .success(true)
                .message("Đã báo cáo nợ xấu thành công!")
                .data(blacklist)
                .build());
    }
    @GetMapping("/{tenantId}/background-check")
    @CheckRole({"OWNER", "STAFF"})
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBackgroundCheck(
            @PathVariable Long tenantId,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        // 1. Kiểm tra danh sách đen thực tế từ DB
        long blacklistCount = tenantBlacklistRepository.countByTenantId(tenantId);

        // 2. Lịch sử hợp đồng
        List<Contract> contracts = contractRepository.findByTenantId(tenantId);

        long totalContracts = contracts.size();
        long completedContracts = contracts.stream()
                .filter(c -> c.getStatus() == ContractStatus.LIQUIDATED
                        || c.getStatus() == ContractStatus.TERMINATED)
                .count();
        long activeContracts = contracts.stream()
                .filter(c -> c.getStatus() == ContractStatus.ACTIVE)
                .count();

        // 3. Tính điểm tín dụng nội bộ
        // Bắt đầu với 600 điểm baseline, +/- theo hành vi
        int internalScore = 600;
        internalScore += (int)(completedContracts * 30);   // +30 mỗi hợp đồng hoàn thành tốt
        internalScore += (int)(activeContracts * 20);       // +20 đang thuê active
        internalScore -= (int)(blacklistCount * 150);       // -150 mỗi lần vào blacklist
        internalScore = Math.max(0, Math.min(900, internalScore));

        boolean hasDebt = blacklistCount > 0;
        String summary;
        if (blacklistCount > 0) {
            summary = String.format("Cảnh báo: Đã từng bị báo cáo nợ xấu %d lần. Cần thẩm định kỹ.", blacklistCount);
        } else if (internalScore >= 750) {
            summary = "Hồ sơ tốt. Lịch sử thuê phòng tích cực.";
        } else if (internalScore >= 600) {
            summary = "Hồ sơ bình thường. Chưa có vi phạm ghi nhận.";
        } else {
            summary = "Hồ sơ mới, chưa có lịch sử thuê phòng.";
        }

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("internalCreditScore", internalScore);
        details.put("totalContracts", totalContracts);
        details.put("completedContracts", completedContracts);
        details.put("activeContracts", activeContracts);
        details.put("blacklistReports", blacklistCount);
        details.put("hasDebt", hasDebt);
        details.put("summary", summary);
        details.put("note", "Điểm tín dụng nội bộ StayHub — không phải điểm tín dụng ngân hàng chính thức.");

        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Đã hoàn tất kiểm tra lý lịch")
                .data(details)
                .build());
    }
}
