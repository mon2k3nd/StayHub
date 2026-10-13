package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.CashService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.stayhub.api.entity.User;

import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.util.Map;

@RestController
@RequestMapping("/v1/cash")
@RequiredArgsConstructor
public class V1CashController {

    private final CashService cashService;

    @PostMapping("/generate-qr")
    public ResponseEntity<ApiResponse<Map<String, String>>> generateQr(
            Authentication authentication,
            @RequestParam String sessionType,
            @RequestParam(required = false) Long branchId) {
        
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, String>>builder().success(false).message("Yêu cầu xác thực").build());
        }
        
        boolean isStaff = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (!isStaff && !isOwner) {
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, String>>builder().success(false).message("Khách thuê không có quyền tạo mã QR giao dịch").build());
        }

        if ("STAFF_HANDOVER_CASH".equals(sessionType) && !isOwner) {
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, String>>builder().success(false).message("Chỉ Chủ nhà mới có thể tạo mã nhận tiền nộp từ nhân viên").build());
        }
        
        Long userId = (Long) authentication.getPrincipal();
        ApiResponse<Map<String, String>> response = cashService.generateQr(userId, sessionType, branchId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/preview-scan")
    public ResponseEntity<ApiResponse<Map<String, Object>>> previewScan(
            Authentication authentication,
            @RequestParam String sessionId) {
        
        Long userId = (Long) authentication.getPrincipal();
        ApiResponse<Map<String, Object>> response = cashService.previewScan(userId, sessionId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/scan-qr")
    public ResponseEntity<ApiResponse<Void>> scanQr(
            Authentication authentication,
            @RequestParam String sessionId,
            @RequestParam Double amount,
            @RequestParam(required = false) java.util.List<Long> itemIds) {
        
        Long userId = (Long) authentication.getPrincipal();
        ApiResponse<Void> response = cashService.scanQr(userId, sessionId, amount, itemIds);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @GetMapping(value = "/stream/{ownerId}", produces = org.springframework.http.MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamEvents(
            Authentication authentication,
            @PathVariable Long ownerId) {
            
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new org.springframework.security.access.AccessDeniedException("Yêu cầu xác thực");
        }
        Long userId = (Long) authentication.getPrincipal();
        if (!userId.equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền truy cập luồng thông báo này");
        }
        return cashService.createSseEmitter(ownerId);
    }

    @PostMapping("/confirm")
    public ResponseEntity<ApiResponse<Void>> confirmSession(
            Authentication authentication,
            @RequestParam String sessionId) {
        
        Long userId = (Long) authentication.getPrincipal();
        ApiResponse<Void> response = cashService.confirmSession(userId, sessionId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/cancel")
    public ResponseEntity<ApiResponse<Void>> cancelSession(
            Authentication authentication,
            @RequestParam String sessionId) {
        
        Long userId = (Long) authentication.getPrincipal();
        ApiResponse<Void> response = cashService.cancelSession(userId, sessionId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
