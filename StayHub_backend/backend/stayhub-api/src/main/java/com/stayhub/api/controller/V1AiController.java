package com.stayhub.api.controller;

import com.stayhub.api.service.FinancialAiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/ai")
@RequiredArgsConstructor
public class V1AiController {

    private final FinancialAiService financialAiService;

    /**
     * Lấy lời khuyên tài chính từ AI cho chủ nhà.
     * Dữ liệu gửi đi chỉ là số liệu tổng hợp, không chứa thông tin cá nhân khách thuê.
     *
     * @param ownerId ID của chủ nhà
     * @param month   Tháng cần phân tích (null = tháng hiện tại)
     * @param year    Năm cần phân tích (null = năm hiện tại)
     */
    @GetMapping("/financial-advice/{ownerId}")
    public ResponseEntity<Map<String, Object>> getFinancialAdvice(
            @PathVariable Long ownerId,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {
        try {
            String advice = financialAiService.getFinancialAdvice(ownerId, month, year);
            return ResponseEntity.ok(Map.of("success", true, "data", advice));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of(
                "success", false,
                "data", "## ⚠️ Lỗi hệ thống\nKhông thể phân tích dữ liệu lúc này. Vui lòng thử lại sau."
            ));
        }
    }
}
