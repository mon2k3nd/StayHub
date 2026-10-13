package com.stayhub.api.controller;

import com.stayhub.api.config.CheckRole;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.AdminService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/admin")
@RequiredArgsConstructor
@Slf4j
@CheckRole("ADMIN")
public class V1AdminController {

    private final AdminService adminService;

    @GetMapping("/owners")
    public ResponseEntity<ApiResponse<java.util.List<Map<String, Object>>>> getOwners(@RequestParam(required = false) String status) {
        return ResponseEntity.ok(ApiResponse.<java.util.List<Map<String, Object>>>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getOwners(status))
                .build());
    }

    @GetMapping("/tenants")
    public ResponseEntity<ApiResponse<java.util.List<Map<String, Object>>>> getTenants(@RequestParam(required = false) String search) {
        return ResponseEntity.ok(ApiResponse.<java.util.List<Map<String, Object>>>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getTenants(search))
                .build());
    }

    @PutMapping("/owners/{id}/verify")
    public ResponseEntity<ApiResponse<Void>> verifyOwner(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        boolean approved = Boolean.parseBoolean(body.get("approved").toString());
        String reason = body.containsKey("reason") ? body.get("reason").toString() : null;

        adminService.verifyOwner(id, adminId, approved, reason);

        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Đã xét duyệt hồ sơ thành công")
                .build());
    }

    @PutMapping("/owners/{id}/override")
    public ResponseEntity<ApiResponse<Void>> overrideOwner(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1"));
        adminService.overrideOwnerData(id, adminId, body);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Đã ghi đè thông tin chủ nhà")
                .build());
    }

    @PutMapping("/owners/{id}/ban")
    public ResponseEntity<ApiResponse<Void>> banOwner(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        boolean isBanned = Boolean.parseBoolean(body.get("isBanned").toString());
        adminService.banOwner(id, adminId, isBanned);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message(isBanned ? "Đã khóa sàn của chủ nhà" : "Đã mở khóa sàn cho chủ nhà")
                .build());
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboardStats() {
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getDashboardStats())
                .build());
    }

    @GetMapping("/omni-search")
    public ResponseEntity<ApiResponse<java.util.List<Map<String, Object>>>> omniSearch(@RequestParam String query) {
        return ResponseEntity.ok(ApiResponse.<java.util.List<Map<String, Object>>>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.omniSearch(query))
                .build());
    }

    @GetMapping("/users/{userId}/details")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUserDetails(@PathVariable Long userId) {
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getUserDetails(userId))
                .build());
    }

    @PutMapping("/finance/reconciliation/{billId}/override")
    public ResponseEntity<ApiResponse<Void>> overrideBill(
            @PathVariable Long billId,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        adminService.overrideBillStatus(billId, adminId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Đã ép cập nhật hóa đơn thành công")
                .build());
    }

    @GetMapping("/map/coordinates")
    public ResponseEntity<ApiResponse<Object>> getCoordinates() {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getBranchCoordinates())
                .build());
    }
    @GetMapping("/saas/plans")
    public ResponseEntity<ApiResponse<Object>> getSaasPlans() {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getAllSaasPlans())
                .build());
    }

    @PostMapping("/saas/plans")
    public ResponseEntity<ApiResponse<Object>> createSaasPlan(@RequestBody com.stayhub.api.entity.SaasPlan plan) {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.saveSaasPlan(plan))
                .build());
    }

    @GetMapping("/saas/campaigns")
    public ResponseEntity<ApiResponse<Object>> getCampaigns() {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getAllCampaigns())
                .build());
    }

    @PostMapping("/saas/campaigns")
    public ResponseEntity<ApiResponse<Object>> createCampaign(@RequestBody com.stayhub.api.entity.SaasMarketingCampaign campaign) {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.saveCampaign(campaign))
                .build());
    }

    @GetMapping("/legal-blueprints")
    public ResponseEntity<ApiResponse<Object>> getLegalBlueprints() {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getAllLegalBlueprints())
                .build());
    }

    @PostMapping("/legal-blueprints")
    public ResponseEntity<ApiResponse<Object>> createLegalBlueprint(@RequestBody com.stayhub.api.entity.SystemLegalBlueprint blueprint) {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.saveLegalBlueprint(blueprint))
                .build());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<Object>> getAuditLogs() {
        return ResponseEntity.ok(ApiResponse.<Object>builder()
                .success(true)
                .message("Thành công")
                .data(adminService.getAuditLogs())
                .build());
    }

    // --- ADMIN DEEP INTERVENTIONS ---

    @PutMapping("/tenants/{id}/unban")
    public ResponseEntity<ApiResponse<Void>> unbanTenant(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        String reason = body.containsKey("reason") ? body.get("reason").toString() : null;
        adminService.unbanTenant(id, adminId, reason);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã mở khoá tài khoản khách thuê").build());
    }

    @PutMapping("/tenants/{id}/trust-score")
    public ResponseEntity<ApiResponse<Void>> updateTrustScore(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        int newScore = Integer.parseInt(body.get("newScore").toString());
        String reason = body.containsKey("reason") ? body.get("reason").toString() : null;
        adminService.updateTrustScore(id, adminId, newScore, reason);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã cập nhật điểm tín nhiệm").build());
    }

    @DeleteMapping("/blacklists/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBlacklist(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        String reason = body.containsKey("reason") ? body.get("reason").toString() : null;
        adminService.deleteBlacklist(id, adminId, reason);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xoá báo cáo xấu").build());
    }

    @PutMapping("/tenants/{id}/unlink-cccd")
    public ResponseEntity<ApiResponse<Void>> unlinkCccd(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        String reason = body.containsKey("reason") ? body.get("reason").toString() : null;
        adminService.unlinkCccd(id, adminId, reason);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã gỡ liên kết CCCD").build());
    }

    @PutMapping("/tenants/{id}/approve-ekyc")
    public ResponseEntity<ApiResponse<Void>> manualEkyc(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long adminId = Long.valueOf(body.getOrDefault("adminId", "1").toString());
        String cccdNumber = body.containsKey("cccdNumber") && body.get("cccdNumber") != null ? body.get("cccdNumber").toString() : null;
        String reason = body.containsKey("reason") && body.get("reason") != null ? body.get("reason").toString() : null;
        boolean isApproved = body.containsKey("isApproved") ? Boolean.parseBoolean(body.get("isApproved").toString()) : true;
        
        adminService.manualEkyc(id, adminId, cccdNumber, reason, isApproved);
        
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã cập nhật trạng thái eKYC").build());
    }
}
