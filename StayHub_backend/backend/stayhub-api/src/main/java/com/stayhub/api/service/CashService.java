package com.stayhub.api.service;

import com.stayhub.api.dto.response.ApiResponse;
import java.util.Map;

import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

public interface CashService {
    ApiResponse<Map<String, String>> generateQr(Long userId, String sessionType, Long branchId);
    ApiResponse<Map<String, Object>> previewScan(Long scannerUserId, String sessionId);
    ApiResponse<Void> scanQr(Long scannerUserId, String sessionId, Double amount, java.util.List<Long> itemIds);
    ApiResponse<Void> confirmSession(Long userId, String sessionId);
    ApiResponse<Void> cancelSession(Long userId, String sessionId);
    SseEmitter createSseEmitter(Long ownerId);
}
