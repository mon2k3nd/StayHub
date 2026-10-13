package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.Review;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/v1/reviews")
@RequiredArgsConstructor
public class V1ReviewController {

    private final ReviewRepository repository;
    private final ContractRepository contractRepository;

    @PostMapping
    public ResponseEntity<ApiResponse<Review>> submitReview(
            @RequestBody Review review,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Yêu cầu xác thực"));
        }
        Long tenantId = (Long) auth.getPrincipal();

        // ── Eligibility check: phải từng có hợp đồng với phòng này ──
        if (review.getRoomId() == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("roomId không được để trống"));
        }
        boolean hasContract = contractRepository.findByRoomId(review.getRoomId())
                .stream()
                .anyMatch(c -> tenantId.equals(c.getTenantId())
                        && (c.getStatus() == ContractStatus.ACTIVE
                        || c.getStatus() == ContractStatus.LIQUIDATED
                        || c.getStatus() == ContractStatus.TERMINATED));
        if (!hasContract) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("Chỉ khách đã từng thuê phòng này mới được đánh giá"));
        }

        // Khoá tenantId từ token, không để client tự điền để giả mạo
        review.setTenantId(tenantId);
        review.setCreatedAt(LocalDateTime.now());
        if (review.getReviewerName() == null) {
            review.setReviewerName("Khách thuê ẩn danh");
        }
        return ResponseEntity.ok(ApiResponse.ok(repository.save(review)));
    }

    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<List<Review>>> getReviewsByRoom(@PathVariable Long roomId) {
        return ResponseEntity.ok(ApiResponse.ok(repository.findByRoomIdOrderByCreatedAtDesc(roomId)));
    }
}
